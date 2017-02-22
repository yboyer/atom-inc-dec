_aEnums = [
    [ "yes", "no" ]
    [ "Yes", "No" ]
    [ "YES", "NO" ]
    [ "true", "false" ]
    [ "True", "False" ]
    [ "TRUE", "FALSE" ]
    [ "am", "pm" ]
    [ "mon", "tue", "wed", "thu", "fri", "sat", "sun" ]
    [ "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" ]
    [ "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche" ]
    [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
    [ "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre" ]
]

_rRordRegex = new RegExp()
_rNumberRegex = new RegExp()

_reverseEnums = () ->
    for aEnum in _aEnums
        aEnum.reverse()

_findAnEnum = ( sWord ) ->
    for aEnum in _aEnums
        return aEnum if aEnum.indexOf(sWord) > -1
    no

_stringToWordRegExp = (sStr) ->
    _rRordRegex = new RegExp(sStr)

_stringToNumberRegExp = (sStr) ->
    _rNumberRegex = new RegExp(sStr, 'g')

_getPrecision = (iNumber) ->
    d = ( s = iNumber.toString() ).indexOf( '.' ) + 1
    if not d then 0 else s.length - d

_updateValue = (iNumber, iValue) ->
    iPrecision = _getPrecision iNumber

    # TODO: Add boolean config
    # 0.6`-1` -> -1.6 NOT -0.4
    if iPrecision
        if Math.trunc(iNumber) == 0 && (iValue == -1 || iValue == 1)
            return parseFloat(iValue + iNumber.toString().slice(iNumber.toString().indexOf('.')))

    iNumber += iValue
    return parseFloat(iNumber.toFixed(iPrecision))


module.exports =
    config:
        wordRegex:
            title: "Word RegExp"
            description: "A RegExp indicating what constitutes a word"
            type: "string"
            default: "\\w+"
        numberRegex:
            title: "Number RegExp"
            description: "A RegExp indicating what constitutes a number"
            type: "string"
            default: "[-+]?\\d+(\\.\\d+)?"

    activate: ->
        _reverseEnums()
        atom.config.observe "inc-dec.wordRegex", _stringToWordRegExp
        atom.config.observe "inc-dec.numberRegex", _stringToNumberRegExp
        atom.commands.add "atom-text-editor:not([mini])",
            "inc-dec:inc": => @loop()
            "inc-dec:dec": => @loop "down"

    loop: ( sDirection = "up" ) ->
        atom.workspace.getActiveTextEditor().mutateSelectedText (selection) ->
            cursorWordRange = selection.getBufferRange()

            sWord = selection.getText()
            bIsNumber = new RegExp("^#{_rNumberRegex.source}$").test(sWord)

            # Select a word if nothing is selected
            if selection.isEmpty()
                cursorPosition = selection.cursor.getBufferPosition()

                cursorWordRange = selection.cursor.getCurrentLineBufferRange()
                sLine = selection.cursor.editor.getTextInRange cursorWordRange

                while match = _rNumberRegex.exec(sLine)
                    start = match.index
                    end = start + match[0].length

                    if start <= cursorPosition.column <= end
                        cursorWordRange.start.row = cursorPosition.row
                        cursorWordRange.end.row = cursorPosition.row
                        cursorWordRange.start.column = start
                        cursorWordRange.end.column = end
                        sWord = match[0]
                        bIsNumber = true
                        break

                # Retreive the word under cursor
                if bIsNumber isnt true
                    cursorWordRange = selection.cursor.getCurrentWordBufferRange
                        wordRegex: _rRordRegex
                    sWord = selection.cursor.editor.getTextInRange cursorWordRange

                # Select the text to modify
                selection.setBufferRange cursorWordRange

            ## REPLACEMENT ##
            # Number
            if bIsNumber
                iIncrementValue = 1
                iValue = if sDirection is "up" then iIncrementValue else -iIncrementValue
                iNumber = _updateValue(+sWord, iValue)
                sNewWord = iNumber.toString()

            # Enum
            else if aEnum = _findAnEnum sWord
                iValue = aEnum.indexOf(sWord) + (if sDirection is "up" then 1 else -1)
                if iValue >= aEnum.length
                    iValue = 0
                if iValue < 0
                    iValue = aEnum.length - 1

                sNewWord = aEnum[ iValue ]

            # Word
            else
                currentState = switch
                    when sWord.toLowerCase() is sWord then 0
                    when sWord.toUpperCase() is sWord then 2
                    else 1
                wantedState = if sDirection is 'up' then currentState + 1 else currentState - 1

                if wantedState <= 0
                    sNewWord = sWord.toLowerCase()
                else if wantedState == 1
                    sNewWord = sWord.slice(0, 1).toUpperCase() + sWord.slice(1).toLowerCase()
                else
                    sNewWord = sWord.toUpperCase()

            # Edit the selected text
            selection.insertText sNewWord,
              select: true
