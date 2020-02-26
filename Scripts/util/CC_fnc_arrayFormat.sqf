private _newline = toString [13, 10];
private _contentSeparator = format [",%1", _newline];

private _lines = _this apply { format ["  %1", _x]; };
private _content = _lines joinString _contentSeparator;

["[", _content, "]"] joinString _newline;
