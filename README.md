# Barbearia Oliveira — agendamento online

Site de agendamento de uma página só (`index.html`), sem build. Mobile-first, nas cores preto,
branco, azul claro e azul escuro. Os dados ficam em um banco gratuito no Supabase.

## O que tem

- Escolha do serviço: corte (R$ 20), luzes (R$ 60), corte + luzes (R$ 80), nevou (R$ 70) e corte + nevou (R$ 90)
- Agenda dos próximos 30 dias com os horários livres, atualizada para todos os clientes
- Formulário curto: nome e WhatsApp
- Confirmação na hora, com código e mensagem de lembrete para copiar
- Área do barbeiro (com login): agendamentos do dia, concluir, cancelar, bloquear horários, ranking de clientes e relatório do mês

## Como ligar o banco de dados (Supabase, gratuito)

1. Crie uma conta em https://supabase.com e um projeto novo (guarde a senha do banco).
2. No projeto, abra **SQL Editor**, cole o conteúdo de `supabase/schema.sql` e clique em **Run**.
3. Crie o login do barbeiro em **Authentication > Users > Add user > Create new user**, com e-mail e senha
   (marque a opção de confirmar o e-mail automaticamente).
4. Em **Authentication**, desligue a opção de permitir novos cadastros (**Allow new users to sign up**,
   dentro das configurações de login por e-mail). Assim, só o barbeiro tem conta.
5. Volte ao **SQL Editor** e rode, com o e-mail do passo 3:
   ```sql
   insert into public.admins (email) values ('seu-email@exemplo.com');
   ```
6. Em **Project Settings > API**, copie a **Project URL** e a chave **anon / public**.
7. No `index.html`, cole os dois valores no começo do `<script>`:
   ```js
   var SUPABASE_URL = 'https://xxxx.supabase.co';
   var SUPABASE_ANON_KEY = 'sua-chave-anon';
   ```
8. Salve no GitHub. O Vercel publica a nova versão sozinho.

A chave `anon` é pública por natureza e pode ficar no código. **Nunca** coloque a chave `service_role`.
Quem protege os dados é o próprio banco: os clientes só conseguem reservar horários, e só o e-mail
cadastrado em `admins` lê nomes, contatos e valores.

### Entrar como barbeiro

No rodapé do site, toque em **Área do barbeiro** e entre com o e-mail e a senha do passo 3.
Aparecem as abas Painel e Clientes. O mesmo link vira **Sair** depois do login.

## Como funciona

- O cliente escolhe serviço, dia e horário e confirma. O horário é reservado no banco na hora e some
  da agenda de todos. Dois clientes nunca ficam com o mesmo horário.
- A agenda se atualiza sozinha a cada 20 segundos.
- Cada agendamento ocupa um horário de 30 minutos.
- O "pago" do ranking e do relatório conta só os atendimentos marcados como **Concluir** no painel.

## O que mudar no código

No começo do `<script>`, em `Configuração`:

- `WHATSAPP_BARBEARIA`: número com DDI e DDD, só dígitos
- `HORARIO`: faixas de atendimento por dia da semana, em minutos (`780` = 13:00)
- `SERVICOS`: nomes, descrições e preços
- `PASSO` e `DIAS`: tamanho de cada horário e quantos dias a agenda mostra

Horários e preços também são conferidos no servidor. Se mudar `HORARIO` ou `SERVICOS`, ajuste a função
`criar_agendamento` em `supabase/schema.sql` e rode o arquivo de novo no SQL Editor.

O WhatsApp e o Instagram do rodapé estão no HTML, na tag `<footer>`.

## Sem Supabase (modo de teste)

Com `SUPABASE_URL` e `SUPABASE_ANON_KEY` vazios, o site funciona só no aparelho de cada cliente:
o barbeiro não vê os agendamentos e a Área do barbeiro não aparece.

## Observação sobre o plano gratuito

Até onde sei, projetos gratuitos do Supabase são pausados depois de cerca de uma semana sem uso.
Se isso acontecer, é só reativar no painel do Supabase.
