defmodule Armature.CssGuards do
  @moduledoc false

  @named_colours ~w(aliceblue antiquewhite aqua aquamarine azure beige bisque black
    blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral
    cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgrey
    darkgreen darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon
    darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink
    deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro
    ghostwhite gold goldenrod gray grey green greenyellow honeydew hotpink indianred indigo
    ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan
    lightgoldenrodyellow lightgray lightgrey lightgreen lightpink lightsalmon lightseagreen
    lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen
    magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen
    mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream
    mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid
    palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum
    powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown
    seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen
    steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow
    yellowgreen transparent currentcolor accentcolor accentcolortext activetext buttonborder
    buttonface buttontext canvas canvastext field fieldtext graytext highlight highlighttext
    linktext mark marktext selecteditem selecteditemtext visitedtext activeborder activecaption
    appworkspace background buttonhighlight buttonshadow captiontext inactiveborder
    inactivecaption inactivecaptiontext infobackground infotext menu menutext scrollbar
    threeddarkshadow threedface threedhighlight threedlightshadow threedshadow window
    windowframe windowtext)

  @doc "Whether CSS text contains a colour literal outside names, strings and property names."
  def colour_literal?(text) do
    # Ignore custom-property names, class names, strings and property names.
    text = Regex.replace(~r/(?:--[\w-]+|\.[a-z][\w-]*|"[^"]*")/i, text, "")
    text = Regex.replace(~r/\b[a-z][\w-]*\s*:/i, text, "")
    named = Enum.join(@named_colours, "|")

    Regex.match?(~r/#[0-9a-f]{3,8}\b|\b(?:rgba?|hsla?|oklch|oklab|lab|lch|color)\s*\(/i, text) or
      Regex.match?(Regex.compile!("\\b(?:#{named})\\b", "i"), text)
  end
end
