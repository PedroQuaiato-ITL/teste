import os

class PathLocation:
    @staticmethod
    def files_location_queries(nome_arquivo: str):
        try:
            dag_path = os.path.dirname(os.path.abspath(__file__))

            project_root = os.path.abspath(os.path.join(dag_path, "..", ".."))
            queries_path = os.path.join(project_root, "queries")

            if not os.path.exists(queries_path):
                raise FileNotFoundError(f"Pasta não encontrada: {queries_path}")

            full_path = os.path.join(queries_path, nome_arquivo)

            if not os.path.exists(full_path):
                raise FileNotFoundError(f"Arquivo não encontrado: {full_path}")

            return full_path

        except Exception as erro:
            print("Erro ao localizar os arquivos de forma dinâmica:", erro)
            raise erro
