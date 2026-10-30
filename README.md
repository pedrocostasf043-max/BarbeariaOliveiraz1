# Barbearia Oliveira — agendamento online

Site de agendamento de uma página só (`index.html`), sem build e sem dependências.
Mobile-first, nas cores preto, branco, azul claro e azul escuro.

## O que tem

- Escolha do serviço: corte (R$ 20), luzes (R$ 60), corte + luzes (R$ 80), nevou (R$ 70) e corte + nevou (R$ 90)
- Agenda dos próximos 30 dias com os horários livres
- Formulário curto: nome e WhatsApp
- Confirmação com código, mensagem de lembrete para copiar e botão para enviar o pedido ao WhatsApp da barbearia
- Painel do barbeiro: agendamentos do dia, concluir, cancelar, bloquear horários
- Aba Clientes: ranking de quem mais agendou e relatório do mês

## Como publicar de graça no GitHub Pages

1. Crie um repositório novo no GitHub (por exemplo `barbearia-oliveira`).
2. Envie `index.html` e `README.md` (botão **Add file > Upload files**).
3. Vá em **Settings > Pages**.
4. Em **Build and deployment**, escolha **Deploy from a branch**, branch `main`, pasta `/ (root)`, e salve.
5. Em um ou dois minutos o site fica em `https://SEU-USUARIO.github.io/barbearia-oliveira/`.

Para testar no computador, basta abrir o `index.html` no navegador.

## O que mudar no código

Tudo fica no começo do `<script>`, em `Configuração`:

- `WHATSAPP_BARBEARIA`: número com DDI e DDD, só dígitos
- `HORARIO`: faixas de atendimento por dia da semana, em minutos (`780` = 13:00)
- `SERVICOS`: nomes, descrições e preços
- `PASSO`: tamanho de cada horário, em minutos (hoje, 30)
- `DIAS`: quantos dias à frente a agenda mostra (hoje, 30)

O WhatsApp e o Instagram do rodapé estão no HTML, na tag `<footer>`.

## Limitação importante

Esta versão **não tem banco de dados compartilhado**. Os agendamentos de um cliente ficam salvos
só no aparelho dele (`localStorage`). Por isso, hospedado no GitHub Pages:

- o barbeiro não vê os agendamentos dos clientes;
- o painel do barbeiro e a aba Clientes não aparecem;
- dois clientes podem escolher o mesmo horário.

O pedido só chega ao barbeiro se o cliente tocar em **Enviar pelo WhatsApp** na confirmação.

Para o site funcionar de verdade, é preciso ligar um banco de dados e um login para o barbeiro.
Supabase e Firebase têm plano gratuito para isso. As chamadas ao banco estão concentradas
nas funções `createBooking` e `initCaps` do `index.html`.
