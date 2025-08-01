SELECT 
    e.razaosocial,
    e.nome AS revenda,
    e.cnpjcpf AS cpf_cnpj_revenda,
    e.bairro,
    e.cep,
    cid.nome AS cidade,
    est.nome AS estado,
    e.email,
    gerente.nome AS gerente,
    classificacao.descricao AS categoria
FROM entidade e
LEFT JOIN cidade cid ON e.idcidade = cid.id
LEFT JOIN estado est ON e.idestado = est.id
LEFT JOIN entidade gerente ON gerente.id = e.idrepresentante
LEFT JOIN classificacaocliente classificacao ON e.idclassificacaocliente = classificacao.id
WHERE 
    e.cliente = '1'
    AND e.tiporevenda = '1'
    AND e.inativo = '0'
	AND gerente.nome IS NOT NULL
ORDER BY 
    e.nome ASC;