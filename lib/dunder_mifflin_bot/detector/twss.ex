defmodule DunderMifflinBot.Detector.TWSS do
  use Gettext, backend: DunderMifflinBot.Gettext

  defp patterns_en do
    [
      ~r/that'?s? what she said/i,
      ~r/that('s| is| was) (so |really |very |so very )?(big|huge|long|hard|thick|deep|tight|wide|fast|rough|stiff)/i,
      ~r/(put|stick|shove|slide|push|insert|slip) it (in|inside|there|anywhere)/i,
      ~r/(can't|cannot) (fit|get) it (in|inside|through)/i,
      ~r/(too (big|long|hard|thick|wide|tight|deep|fast|slow|rough|stiff) (for|to))/i,
      ~r/(it's|it is|that's|that is) (so |really |very )?(tight|big|huge|long|hard|deep|wide|rough)/i,
      ~r/(harder|faster|deeper|tighter|bigger|longer|wider)/i,
      ~r/how (long|big|deep|thick|wide|hard|fast) (is|was|are|were) (it|that|this|they)/i,
      ~r/(i|we) (can|could|should|would|will)('t| not)? (do|handle|take|fit) (it|that|this|more)/i,
      ~r/(all night|all day|for hours|so long|too long)/i,
      ~r/just the tip/i,
      ~r/do it (harder|faster|slower|softer|deeper|longer)/i
    ]
  end

  defp patterns_pt do
    [
      ~r/(isso|essa|isto) (e|foi) o que ela disse/i,
      ~r/(foi) o que ela disse/i,
      ~r/(la ele|laele|l[aá] ele)/i,
      ~r/(muito|tao|t[ãa]o) (grande|longo|duro|fundo|apertado|rapido|r[aá]pido)/i,
      ~r/(nao|n[aã]o) (cabe|entra)/i,
      ~r/\b(coloca|mete|enfia|bota)(\s+(isso|ele|ai|a[ií]|aqui|dentro))?\b/i,
      ~r/(coloca|mete|enfia|bota) (isso|ele) (ai|a[ií]|dentro)/i,
      ~r/(so|s[oó]) a cabecinha/i
    ]
  end

  def twss?(message, locale \\ "en") do
    text = String.downcase(message)

    patterns =
      case locale do
        "pt_BR" -> patterns_en() ++ patterns_pt()
        _ -> patterns_en()
      end

    Enum.any?(patterns, &Regex.match?(&1, text))
  end

  def michael_response(_locale \\ "en") do
    responses = [
      dgettext("events", "twss_response_1"),
      dgettext("events", "twss_response_2"),
      dgettext("events", "twss_response_3"),
      dgettext("events", "twss_response_4")
    ]

    Enum.random(responses)
  end
end
