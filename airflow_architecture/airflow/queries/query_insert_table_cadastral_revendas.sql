INSERT INTO registro_cadastral_revendas (
    uuid, revenda, razao_social, cnpj, bairro, cep, cidade, estado,email, gerente, categoria
) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
