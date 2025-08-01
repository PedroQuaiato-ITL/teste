SELECT hdr.*, rcr.gerente FROM public.registro_historico_desempenho_revendas hdr
LEFT JOIN public.registro_cadastral_revendas rcr ON hdr.uuid = rcr.uuid
WHERE data_registro = (SELECT MAX(data_registro) FROM public.registro_historico_desempenho_revendas)
ORDER BY rcr.gerente ASC, revenda ASC