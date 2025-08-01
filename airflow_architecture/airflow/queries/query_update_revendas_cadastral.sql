UPDATE registro_cadastral_revendas SET
    razao_social = %s,
    cnpj = %s,
    bairro = %s,
    cep = %s,
    cidade = %s,
    estado = %s,
    email = %s,
    gerente = %s,
    categoria = %s
WHERE revenda = %s;