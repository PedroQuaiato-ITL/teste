SELECT 
    s2.tiposeq,
    s2.tipo,
    s2.idrevenda,
    s2.idgerente,
    s2.descricao AS nomerevenda,  -- Nome da revenda
    SUM(s2.qtd) AS qtdfaturado,
    SUM(s2.qtddegustacao) AS qtddegustacao,
    SUM(s2.valortotal - s2.valorlicencadegustacao) AS valorfaturado,
    SUM(s2.valorcontratodegustacao + s2.valorlicencadegustacao) AS valordegustacao
FROM (
    SELECT 
        s.idrevenda,
        s.tiposeq,
        s.tipo,
        s.descricao,
        s.valortotal,
        s.valorcontratodegustacao,
        s.qtd,
        s.qtddegustacao,
        s.ordem,
        s.idgerente,
        s.idrevenda,
        SUM(s.valorlicencadegustacao) AS valorlicencadegustacao
    FROM (
        SELECT 
            6::bigint AS tiposeq,
            'Contratos por revenda'::text AS tipo,
            cc.ordem,
            r.nome AS descricao,  -- Aqui já está o nome da revenda
            c.codigo,
            ger.id AS idgerente,
            r.id AS idrevenda,
            CASE
                WHEN c.status = ANY (ARRAY[1, 3]) THEN 1 ELSE 0
            END AS qtd,
            CASE
                WHEN c.status = 5 THEN 1 ELSE 0
            END AS qtddegustacao,
            CASE
                WHEN c.status = ANY (ARRAY[1, 3]) THEN c.valortotal ELSE 0::numeric
            END AS valortotal,
            CASE
                WHEN c.status = 5 THEN c.valortotal ELSE 0::numeric
            END AS valorcontratodegustacao,
            CASE
                WHEN (c.status = ANY (ARRAY[1, 3])) AND cvi.status = 3 THEN cvi.valortotal ELSE 0::numeric
            END AS valorlicencadegustacao
        FROM entidade r
        LEFT JOIN contratovenda c ON c.idcliente = r.id
        LEFT JOIN contratovendaitem cvi ON cvi.idcontrato = c.id
        LEFT JOIN classificacaocliente cc ON cc.id = r.idclassificacaocliente
        LEFT JOIN entidade ger ON ger.id = r.idrepresentante
        LEFT JOIN classificacaocliente clcl ON clcl.id = r.idclassificacaocliente
        WHERE 
            c.status = ANY (ARRAY[1, 3, 5])
            AND cvi.status = ANY (ARRAY[0, 3])
            AND LOWER(r.nome) NOT LIKE '%intelidata%'
            AND r.tiporevenda = 1
        GROUP BY 
            r.id, c.codigo, c.status, cvi.status, c.valortotal, cvi.valortotal, 
            r.nome, cc.ordem, ger.id
    ) s
    GROUP BY 
        s.idrevenda, s.tiposeq, s.tipo, s.descricao, s.codigo, 
        s.valortotal, s.valorcontratodegustacao, s.qtd, s.qtddegustacao, 
        s.ordem, s.idgerente
) s2(
    idrevenda, tiposeq, tipo, descricao, valortotal, 
    valorcontratodegustacao, qtd, qtddegustacao, ordem, 
    idgerente, idrevenda_1, valorlicencadegustacao
)
GROUP BY 
    s2.tiposeq, s2.tipo, s2.descricao, s2.ordem, 
    s2.idgerente, s2.idrevenda
ORDER BY 
    s2.descricao;
