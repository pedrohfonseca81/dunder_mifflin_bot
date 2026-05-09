defmodule DunderMifflinBot.Commands.Registry do
  def commands do
    [
      %{
        name: "michael",
        description: "Michael Scott gives his take on a subject",
        name_localizations: %{"pt-BR" => "michael"},
        description_localizations: %{"pt-BR" => "Michael Scott dá sua opinião sobre um assunto"},
        options: [option_string("subject", "What should Michael talk about?", "assunto", "Sobre o que o Michael deve falar?")]
      },
      %{
        name: "dwight",
        description: "Dwight writes a formal incident report",
        name_localizations: %{"pt-BR" => "dwight"},
        description_localizations: %{"pt-BR" => "Dwight escreve um relatório de incidente"},
        options: [
          option_user("person", "Who is the target?", "pessoa", "Quem é o alvo?"),
          option_string("reason", "Reason for the report", "motivo", "Motivo do relatório")
        ]
      },
      %{
        name: "jim",
        description: "Jim talks to the camera about recent messages",
        name_localizations: %{"pt-BR" => "jim"},
        description_localizations: %{"pt-BR" => "Jim fala pra câmera sobre as mensagens recentes"}
      },
      %{
        name: "kevin",
        description: "Kevin explains something in his own way",
        name_localizations: %{"pt-BR" => "kevin"},
        description_localizations: %{"pt-BR" => "Kevin explica algo do seu jeito"},
        options: [option_string("topic", "What should Kevin explain?", "assunto", "O que o Kevin deve explicar?")]
      },
      %{
        name: "creed",
        description: "Creed says something weird",
        name_localizations: %{"pt-BR" => "creed"},
        description_localizations: %{"pt-BR" => "Creed fala algo estranho"}
      },
      %{
        name: "stanley",
        description: "Stanley reacts with complete indifference",
        name_localizations: %{"pt-BR" => "stanley"},
        description_localizations: %{"pt-BR" => "Stanley reage com total indiferença"}
      },
      %{
        name: "toby",
        description: "Toby mediates (badly)",
        name_localizations: %{"pt-BR" => "toby"},
        description_localizations: %{"pt-BR" => "Toby tenta mediar (mal)"},
        options: [
          option_user("person", "Who is involved?", "pessoa", "Quem está envolvido?"),
          option_string("reason", "What is the issue?", "motivo", "Qual é o problema?")
        ]
      },
      %{
        name: "andy",
        description: "Andy sings about it",
        name_localizations: %{"pt-BR" => "andy"},
        description_localizations: %{"pt-BR" => "Andy canta sobre isso"},
        options: [option_string("subject", "What should Andy sing about?", "assunto", "Sobre o que Andy deve cantar?")]
      },
      %{
        name: "oscar",
        description: "Oscar corrects you",
        name_localizations: %{"pt-BR" => "oscar"},
        description_localizations: %{"pt-BR" => "Oscar te corrige"},
        options: [option_string("subject", "What should Oscar correct?", "assunto", "O que Oscar deve corrigir?")]
      },
      %{
        name: "angela",
        description: "Angela judges you",
        name_localizations: %{"pt-BR" => "angela"},
        description_localizations: %{"pt-BR" => "Angela te julga"},
        options: [option_user("person", "Who should Angela judge?", "pessoa", "Quem Angela deve julgar?")]
      },
      %{
        name: "meeting",
        description: "Michael calls someone to the conference room",
        name_localizations: %{"pt-BR" => "reuniao"},
        description_localizations: %{"pt-BR" => "Michael chama alguém pra sala de conferência"},
        options: [
          option_user("person", "Who is being summoned?", "pessoa", "Quem está sendo convocado?"),
          option_string("topic", "Meeting topic", "assunto", "Assunto da reunião")
        ]
      },
      %{
        name: "trial",
        description: "Start a Dunder Mifflin trial",
        name_localizations: %{"pt-BR" => "processar"},
        description_localizations: %{"pt-BR" => "Iniciar um tribunal Dunder Mifflin"},
        options: [
          option_user("person", "Who is being tried?", "pessoa", "Quem está sendo julgado?"),
          option_string("reason", "What are the charges?", "motivo", "Quais são as acusações?")
        ]
      },
      %{
        name: "summary",
        description: "Summarize recent channel messages as a TV episode",
        name_localizations: %{"pt-BR" => "resumo"},
        description_localizations: %{"pt-BR" => "Resumir mensagens recentes como episódio de TV"}
      },
      %{
        name: "translate",
        description: "Translate text (with Oscar's commentary)",
        name_localizations: %{"pt-BR" => "traduzir"},
        description_localizations: %{"pt-BR" => "Traduzir texto (com comentário do Oscar)"},
        options: [
          option_string("text", "Text to translate", "texto", "Texto a traduzir"),
          option_string("language", "Target language", "idioma", "Idioma de destino")
        ]
      },
      %{
        name: "dundie",
        description: "Give someone a Dundie Award",
        name_localizations: %{"pt-BR" => "dundie"},
        description_localizations: %{"pt-BR" => "Dar um Dundie Award a alguém"},
        options: [
          option_user("person", "Who gets the Dundie?", "pessoa", "Quem recebe o Dundie?"),
          option_string("category", "Award category", "categoria", "Categoria do prêmio")
        ]
      },
      %{
        name: "alliance",
        description: "Propose a secret alliance",
        name_localizations: %{"pt-BR" => "aliancar"},
        description_localizations: %{"pt-BR" => "Propor uma aliança secreta"},
        options: [option_user("person", "Alliance partner", "pessoa", "Parceiro de aliança")]
      },
      %{
        name: "vote",
        description: "Start a poll",
        name_localizations: %{"pt-BR" => "votar"},
        description_localizations: %{"pt-BR" => "Iniciar uma votação"},
        options: [
          option_string("option1", "First option", "opcao1", "Primeira opção"),
          option_string("option2", "Second option", "opcao2", "Segunda opção")
        ]
      },
      %{
        name: "shift",
        description: "Clock in for your daily Schrute Bucks",
        name_localizations: %{"pt-BR" => "expediente"},
        description_localizations: %{"pt-BR" => "Bater ponto e ganhar Schrute Bucks diários"}
      },
      %{
        name: "balance",
        description: "Check your Schrute Bucks balance",
        name_localizations: %{"pt-BR" => "saldo"},
        description_localizations: %{"pt-BR" => "Ver seus Schrute Bucks"}
      },
      %{
        name: "pay",
        description: "Transfer Schrute Bucks to another member",
        name_localizations: %{"pt-BR" => "pagar"},
        description_localizations: %{"pt-BR" => "Transferir Schrute Bucks para outro membro"},
        options: [
          option_user("person", "Who to pay", "pessoa", "Para quem pagar"),
          %{
            name: "amount",
            description: "Amount to transfer",
            name_localizations: %{"pt-BR" => "valor"},
            description_localizations: %{"pt-BR" => "Valor a transferir"},
            type: 4,
            required: true,
            min_value: 1
          }
        ]
      },
      %{
        name: "store",
        description: "Buy Schrute Bucks packs",
        name_localizations: %{"pt-BR" => "loja"},
        description_localizations: %{"pt-BR" => "Comprar pacotes de Schrute Bucks"}
      },
      %{
        name: "profile",
        description: "View employee file",
        name_localizations: %{"pt-BR" => "perfil"},
        description_localizations: %{"pt-BR" => "Ver ficha de funcionário"},
        options: [option_user_optional("person", "Whose profile?", "pessoa", "De quem é o perfil?")]
      },
      %{
        name: "dashboard",
        description: "Server quarterly report",
        name_localizations: %{"pt-BR" => "dashboard"},
        description_localizations: %{"pt-BR" => "Relatório trimestral do servidor"}
      },
      %{
        name: "reminder",
        description: "Set a reminder delivered by a character",
        name_localizations: %{"pt-BR" => "lembrete"},
        description_localizations: %{"pt-BR" => "Criar um lembrete entregue por um personagem"},
        options: [
          option_user("person", "Who to remind", "pessoa", "Para quem lembrar"),
          option_string("time", "When (e.g. 10m, 2h, 1d)", "tempo", "Quando (ex: 10m, 2h, 1d)"),
          option_string("message", "The reminder message", "mensagem", "A mensagem do lembrete")
        ]
      },
      %{
        name: "warn",
        description: "Warn a member",
        name_localizations: %{"pt-BR" => "warn"},
        description_localizations: %{"pt-BR" => "Avisar um membro"},
        default_member_permissions: "8192",
        options: [
          option_user("person", "Who to warn", "pessoa", "Quem avisar"),
          option_string("reason", "Reason", "motivo", "Motivo")
        ]
      },
      %{
        name: "mute",
        description: "Mute a member",
        name_localizations: %{"pt-BR" => "mute"},
        description_localizations: %{"pt-BR" => "Silenciar um membro"},
        default_member_permissions: "8192",
        options: [
          option_user("person", "Who to mute", "pessoa", "Quem silenciar"),
          option_string("time", "Duration (e.g. 10m, 1h)", "tempo", "Duração (ex: 10m, 1h)"),
          option_string("reason", "Reason", "motivo", "Motivo")
        ]
      },
      %{
        name: "timeout",
        description: "Timeout a member",
        name_localizations: %{"pt-BR" => "timeout"},
        description_localizations: %{"pt-BR" => "Aplicar timeout em um membro"},
        default_member_permissions: "8192",
        options: [
          option_user("person", "Who to timeout", "pessoa", "Quem aplicar timeout"),
          option_string("time", "Duration", "tempo", "Duração"),
          option_string("reason", "Reason", "motivo", "Motivo")
        ]
      },
      %{
        name: "kick",
        description: "Kick a member",
        name_localizations: %{"pt-BR" => "kick"},
        description_localizations: %{"pt-BR" => "Expulsar um membro"},
        default_member_permissions: "8",
        options: [
          option_user("person", "Who to kick", "pessoa", "Quem expulsar"),
          option_string("reason", "Reason", "motivo", "Motivo")
        ]
      },
      %{
        name: "ban",
        description: "Ban a member",
        name_localizations: %{"pt-BR" => "ban"},
        description_localizations: %{"pt-BR" => "Banir um membro"},
        default_member_permissions: "8",
        options: [
          option_user("person", "Who to ban", "pessoa", "Quem banir"),
          option_string("reason", "Reason", "motivo", "Motivo")
        ]
      },
      %{
        name: "logs",
        description: "View HR incident files",
        name_localizations: %{"pt-BR" => "logs"},
        description_localizations: %{"pt-BR" => "Ver arquivos de incidentes do RH"},
        default_member_permissions: "8192"
      },
      %{
        name: "rules",
        description: "View or set the Employee Manual",
        name_localizations: %{"pt-BR" => "regras"},
        description_localizations: %{"pt-BR" => "Ver ou definir o Manual do Funcionário"},
        default_member_permissions: "8192",
        options: [option_string_optional("content", "Rules content (to set)", "conteudo", "Conteúdo das regras (para definir)")]
      },
      %{
        name: "birthday",
        description: "Register your birthday for The Office style announcements",
        name_localizations: %{"pt-BR" => "aniversario"},
        description_localizations: %{"pt-BR" => "Registrar seu aniversário para anúncios estilo The Office"},
        options: [
          option_string("date", "Your birthday (DD/MM or MM-DD)", "data", "Seu aniversário (DD/MM ou MM-DD)")
        ]
      },
      %{
        name: "help",
        description: "Help — written by Toby",
        name_localizations: %{"pt-BR" => "ajuda"},
        description_localizations: %{"pt-BR" => "Ajuda — escrita pelo Toby"}
      },
      %{
        name: "config",
        description: "Open server settings panel",
        name_localizations: %{"pt-BR" => "config"},
        description_localizations: %{"pt-BR" => "Abrir painel de configurações"},
        default_member_permissions: "8"
      },
      %{
        name: "superadmin",
        description: "Bot owner maintenance commands",
        name_localizations: %{"pt-BR" => "superadmin"},
        description_localizations: %{"pt-BR" => "Comandos de manutenção do dono do bot"},
        default_member_permissions: "0",
        dm_permission: false,
        options: [
          %{
            type: 1,
            name: "ping",
            description: "Check superadmin access",
            name_localizations: %{"pt-BR" => "ping"},
            description_localizations: %{"pt-BR" => "Verificar acesso superadmin"}
          },
          %{
            type: 1,
            name: "sync_commands",
            description: "Re-register all global slash commands",
            name_localizations: %{"pt-BR" => "sync_comandos"},
            description_localizations: %{"pt-BR" => "Re-registrar todos os comandos globais"}
          },
          %{
            type: 1,
            name: "owners",
            description: "Show configured OWNERS_ID list",
            name_localizations: %{"pt-BR" => "owners"},
            description_localizations: %{"pt-BR" => "Mostrar a lista configurada em OWNERS_ID"}
          },
          %{
            type: 1,
            name: "grant_sb",
            description: "Grant Schrute Bucks to a member",
            name_localizations: %{"pt-BR" => "dar_sb"},
            description_localizations: %{"pt-BR" => "Dar Schrute Bucks para um membro"},
            options: [
              %{
                name: "person",
                description: "Who receives Schrute Bucks",
                name_localizations: %{"pt-BR" => "pessoa"},
                description_localizations: %{"pt-BR" => "Quem recebe os Schrute Bucks"},
                type: 6,
                required: true
              },
              %{
                name: "amount",
                description: "Amount to grant",
                name_localizations: %{"pt-BR" => "valor"},
                description_localizations: %{"pt-BR" => "Quantidade a conceder"},
                type: 4,
                required: true,
                min_value: 1
              }
            ]
          }
        ]
      }
    ]
  end

  defp option_string(name, desc, pt_name, pt_desc) do
    %{
      name: name,
      description: desc,
      name_localizations: %{"pt-BR" => pt_name},
      description_localizations: %{"pt-BR" => pt_desc},
      type: 3,
      required: true
    }
  end

  defp option_string_optional(name, desc, pt_name, pt_desc) do
    %{
      name: name,
      description: desc,
      name_localizations: %{"pt-BR" => pt_name},
      description_localizations: %{"pt-BR" => pt_desc},
      type: 3,
      required: false
    }
  end

  defp option_user(name, desc, pt_name, pt_desc) do
    %{
      name: name,
      description: desc,
      name_localizations: %{"pt-BR" => pt_name},
      description_localizations: %{"pt-BR" => pt_desc},
      type: 6,
      required: true
    }
  end

  defp option_user_optional(name, desc, pt_name, pt_desc) do
    %{
      name: name,
      description: desc,
      name_localizations: %{"pt-BR" => pt_name},
      description_localizations: %{"pt-BR" => pt_desc},
      type: 6,
      required: false
    }
  end

  def register_global do
    app_id = Application.get_env(:dunder_mifflin_bot, :discord_application_id)
    Nostrum.Api.ApplicationCommand.bulk_overwrite_global_commands(app_id, commands())
  end
end
