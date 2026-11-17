# Monitor do Resoa

Checa a cada 10 minutos se https://www.resoaclinic.com.br está no ar: a página do site e o servidor (funções da API). Roda fora da Vercel, para avisar mesmo quando a própria hospedagem cai.

- Só considera "fora do ar" depois de 3 falhas seguidas, com 1 minuto entre elas.
- Na queda, abre uma issue com o rótulo `fora-do-ar` e o GitHub manda e-mail. A issue diz se a Vercel informa problema na hospedagem dela.
- Na volta, comenta quanto tempo ficou fora e fecha a issue. Um e-mail por queda, não um a cada 10 minutos.
- Custo zero: repositório público, sem segredos, só endereços públicos.
