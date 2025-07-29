from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
from DAG_financeiro_intelidata.AtualizacaoFinanceiro import AtualizacaoFinanceiroIntelidata

default_args = {
    'owner': 'Pedro',
    'depends_on_past': False,
    'start_date': datetime(2025, 7, 21),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='DAG_atualizacao_financeiro_intelidata',
    default_args=default_args,
    schedule_interval=' 30 1 * * *',
    catchup=False,
    tags=['financeiro', 'intelidata']
) as dag:

    executar_query_gnio = PythonOperator(
        task_id='executar_query_gnio',
        python_callable=AtualizacaoFinanceiroIntelidata.executar_query_gnio,
        provide_context=True
    )

    tratar_dataframe_gnio = PythonOperator(
        task_id='tratar_dataframe_gnio',
        python_callable=AtualizacaoFinanceiroIntelidata.tratar_dataframe_gnio,
        provide_context=True
    )

    inserir_database = PythonOperator(
        task_id='inserir_database',
        python_callable=AtualizacaoFinanceiroIntelidata.inserir_database,
        provide_context=True
    )

    executar_query_gnio >> tratar_dataframe_gnio >> inserir_database
