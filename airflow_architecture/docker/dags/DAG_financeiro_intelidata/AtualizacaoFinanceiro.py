import pandas as pd
import uuid
from airflow.models import Variable
from Modules.DatabaseConfigurationConnection import DatabaseConfigurationConnection as hook


class AtualizacaoFinanceiroIntelidata:

    @staticmethod
    def executar_query_gnio(**kwargs):
        ti = kwargs['ti']
        try:
            connection_gnio, cursor_gnio = hook.databaseConfigurationGnio()

            query = """
                SELECT  
                    f.id as id_original,
                    f.documento,
                    f.emissao as data_emissao,
                    f.vencimento as data_vencimento,
                    f.status as status_documento,
                    f.tipo as tipo_documento,
                    ccr.valor as valor_bruto,
                    f.saldo as valor_pendente,
                    pc.nome as plano_contas,
                    cc.descricao as centro_custo,
                    ccr.percentual
                FROM centrocustorateio ccr
                    JOIN financeiro f ON ccr.idfinanceiro = f.id
                    JOIN centrocusto cc ON ccr.idcentrocusto = cc.id
                    JOIN planocontas pc ON f.idcodigocontabil = pc.id
                WHERE pc.inativo = 0
                ORDER BY
                    (f.emissao IS NULL),
                    f.emissao DESC;
            """

            df = pd.read_sql(query, connection_gnio)

            if df.empty:
                raise ValueError("Query retornou DataFrame vazio!")

            ti.xcom_push(key='extrair_dados_gnio', value=df.to_json(orient='records'))
            print(f"✅ Query executada: {len(df)} registros salvos no XCom.")

        except Exception as erro:
            print(f"🚫 Erro na query GNIO: {erro}")
            raise

    @staticmethod
    def tratar_dataframe_gnio(**kwargs):
        ti = kwargs['ti']
        try:
            df_json = ti.xcom_pull(task_ids='executar_query_gnio', key='extrair_dados_gnio')
            if not df_json:
                raise ValueError("XCom vazio ao puxar DataFrame!")

            df = pd.read_json(df_json, orient='records')

            # UUID
            df.insert(0, 'uuid', [str(uuid.uuid4()) for _ in range(len(df))])

            # Tipo documento
            df['tipo_documento'] = df['tipo_documento'].replace({
                'P': 'Pagar',
                'R': 'Receber'
            })

            # Status documento
            df['status_documento'] = df['status_documento'].replace({
                'A': 'Aberto',
                'Q': 'Quitado',
                'E': 'Excluido',
                'S': 'Substituído',
                'B': 'Baixado',
                'C': 'Cancelado'
            })

            ti.xcom_push(key='tratamento_dataframe', value=df.to_json(orient='records'))
            print(f"✅ Tratamento OK: {len(df)} registros prontos para insert.")

        except Exception as erro:
            print(f"🚫 Erro no tratamento: {erro}")
            raise

    @staticmethod
    def inserir_database(**kwargs):
        ti = kwargs['ti']
        try:
            df_json = ti.xcom_pull(task_ids='tratar_dataframe_gnio', key='tratamento_dataframe')
            if not df_json:
                raise ValueError("XCom vazio no insert!")

            df = pd.read_json(df_json, orient='records')

            if df.empty:
                print("🚫 Nada para inserir: DataFrame vazio.")
                return

            # Tratamento datas
            for col in ['data_emissao', 'data_vencimento']:
                if pd.api.types.is_numeric_dtype(df[col]):
                    max_val = df[col].max()
                    if max_val > 1e10:
                        df[col] = pd.to_datetime(df[col], unit='ms', errors='coerce')
                    else:
                        df[col] = pd.to_datetime(df[col], unit='s', errors='coerce')
                else:
                    df[col] = pd.to_datetime(df[col], errors='coerce')

                df[col] = df[col].dt.strftime('%Y-%m-%d')

            connection_dataset, cursor_dataset = hook.databaseConfigurationDataset()

            # Pega IDs abertos + UUID atual deles
            cursor_dataset.execute("""
                SELECT id_original, uuid FROM public.financeiro_intelidata WHERE status_documento = 'Aberto'
            """)
            id_uuid_map = {row[0]: row[1] for row in cursor_dataset.fetchall()}

            insert_query = """
                INSERT INTO public.financeiro_intelidata (
                    uuid,
                    id_original,
                    documento,
                    data_emissao,
                    data_vencimento,
                    status_documento,
                    tipo_documento,
                    valor_bruto,
                    valor_pendente,
                    plano_contas,
                    centro_custo,
                    percentual
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """

            update_query = """
                UPDATE public.financeiro_intelidata
                SET
                    documento = %s,
                    data_emissao = %s,
                    data_vencimento = %s,
                    status_documento = %s,
                    tipo_documento = %s,
                    valor_bruto = %s,
                    valor_pendente = %s,
                    plano_contas = %s,
                    centro_custo = %s,
                    percentual = %s
                WHERE id_original = %s AND status_documento = 'Aberto'
            """

            insert_count = 0
            update_count = 0

            for _, row in df.iterrows():
                if row['id_original'] in id_uuid_map:
                    # UPDATE => não troca UUID!
                    dados_update = (
                        row['documento'],
                        row['data_emissao'],
                        row['data_vencimento'],
                        row['status_documento'],
                        row['tipo_documento'],
                        row['valor_bruto'],
                        row['valor_pendente'],
                        row['plano_contas'],
                        row['centro_custo'],
                        row['percentual'],
                        row['id_original']
                    )
                    cursor_dataset.execute(update_query, dados_update)
                    update_count += 1
                else:
                    # INSERT => UUID novo
                    dados_insert = (
                        row['uuid'],
                        row['id_original'],
                        row['documento'],
                        row['data_emissao'],
                        row['data_vencimento'],
                        row['status_documento'],
                        row['tipo_documento'],
                        row['valor_bruto'],
                        row['valor_pendente'],
                        row['plano_contas'],
                        row['centro_custo'],
                        row['percentual']
                    )
                    cursor_dataset.execute(insert_query, dados_insert)
                    insert_count += 1

                connection_dataset.commit()

            cursor_dataset.close()
            connection_dataset.close()

            print(f"✅ {update_count} registros ATUALIZADOS, {insert_count} registros INSERIDOS.")

        except Exception as erro:
            print(f"🚫 Erro no insert/update: {erro}")
            raise
