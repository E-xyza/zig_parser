Root <- skip container_doc_comment? ContainerMembers eof

# *** Top level ***
ContainerMembers <- ContainerDeclaration* (ContainerField COMMA)* (ContainerField / ContainerDeclaration*)

ContainerDeclaration <- TestDecl / ComptimeDecl / doc_comment? KEYWORD_pub? Decl

TestDecl <- KEYWORD_test (STRINGLITERALSINGLE / IDENTIFIER)? Block

ComptimeDecl <- KEYWORD_comptime Block

Decl
    <- (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE? / KEYWORD_inline / KEYWORD_noinline)? FnProto (SEMICOLON / Block)
     / (KEYWORD_export / KEYWORD_extern STRINGLITERALSINGLE?)? KEYWORD_threadlocal? GlobalVarDecl
     / KEYWORD_usingnamespace Expr SEMICOLON

FnProto <- KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? AddrSpace? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr

VarDeclProto <- (KEYWORD_const / KEYWORD_var) IDENTIFIER (COLON TypeExpr)? ByteAlign? AddrSpace? LinkSection?

GlobalVarDecl <- VarDeclProto (EQUAL Expr)? SEMICOLON

ContainerField <- doc_comment? KEYWORD_comptime? !KEYWORD_fn (IDENTIFIER COLON)? TypeExpr ByteAlign? (EQUAL Expr)?

# *** Block Level ***
Statement
    <- KEYWORD_comptime ComptimeStatement
     / KEYWORD_nosuspend BlockExprStatement
     / KEYWORD_suspend BlockExprStatement
     / KEYWORD_defer BlockExprStatement
     / KEYWORD_errdefer Payload? BlockExprStatement
     / IfStatement
     / LabeledStatement
     / SwitchExpr
     / VarDeclExprStatement

ComptimeStatement
    <- BlockExpr
     / VarDeclExprStatement

IfStatement
    <- IfPrefix BlockExpr ( KEYWORD_else Payload? Statement )?
     / IfPrefix AssignExpr ( SEMICOLON / KEYWORD_else Payload? Statement )

LabeledStatement <- BlockLabel? (Block / LoopStatement)

LoopStatement <- KEYWORD_inline? (ForStatement / WhileStatement)

ForStatement
    <- ForPrefix BlockExpr ( KEYWORD_else Statement )?
     / ForPrefix AssignExpr ( SEMICOLON / KEYWORD_else Statement )

WhileStatement
    <- WhilePrefix BlockExpr ( KEYWORD_else Payload? Statement )?
     / WhilePrefix AssignExpr ( SEMICOLON / KEYWORD_else Payload? Statement )

BlockExprStatement
    <- BlockExpr
     / AssignExpr SEMICOLON

BlockExpr <- BlockLabel? Block

# An expression, assignment, or any destructure, as a statement.
VarDeclExprStatement
    <- VarDeclProto (COMMA (VarDeclProto / Expr))* EQUAL Expr SEMICOLON
     / Expr (AssignOp Expr / (COMMA (VarDeclProto / Expr))+ EQUAL Expr)? SEMICOLON

# *** Expression Level ***

# An assignment or a destructure whose LHS are all lvalue expressions.
AssignExpr <- Expr (AssignOp Expr / (COMMA Expr)+ EQUAL Expr)?

SingleAssignExpr <- Expr (AssignOp Expr)?

Expr <- BoolOrExpr

BoolOrExpr <- BoolAndExpr (KEYWORD_or BoolAndExpr)*

BoolAndExpr <- CompareExpr (KEYWORD_and CompareExpr)*

CompareExpr <- BitwiseExpr (CompareOp BitwiseExpr)?

BitwiseExpr <- BitShiftExpr (BitwiseOp BitShiftExpr)*

BitShiftExpr <- AdditionExpr (BitShiftOp AdditionExpr)*

AdditionExpr <- MultiplyExpr (AdditionOp MultiplyExpr)*

MultiplyExpr <- PrefixExpr (MultiplyOp PrefixExpr)*

PrefixExpr <- PrefixOp* PrimaryExpr

PrimaryExpr
    <- AsmExpr
     / IfExpr
     / KEYWORD_break BreakLabel? Expr?
     / KEYWORD_comptime Expr
     / KEYWORD_nosuspend Expr
     / KEYWORD_continue BreakLabel?
     / KEYWORD_resume Expr
     / KEYWORD_return Expr?
     / BlockLabel? LoopExpr
     / Block
     / CurlySuffixExpr

IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?

Block <- LBRACE Statement* RBRACE

LoopExpr <- KEYWORD_inline? (ForExpr / WhileExpr)

ForExpr <- ForPrefix Expr (KEYWORD_else Expr)?

WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?

CurlySuffixExpr <- TypeExpr InitList?

InitList
    <- LBRACE FieldInit (COMMA FieldInit)* COMMA? RBRACE
     / LBRACE Expr (COMMA Expr)* COMMA? RBRACE
     / LBRACE RBRACE

TypeExpr <- PrefixTypeOp* ErrorUnionExpr

ErrorUnionExpr <- SuffixExpr (EXCLAMATIONMARK TypeExpr)?

SuffixExpr
    <- KEYWORD_async PrimaryTypeExpr SuffixOp* FnCallArguments
     / PrimaryTypeExpr (SuffixOp / FnCallArguments)*

PrimaryTypeExpr
    <- BUILTINIDENTIFIER FnCallArguments
     / CHAR_LITERAL
     / ContainerDecl
     / DOT IDENTIFIER
     / DOT InitList
     / ErrorSetDecl
     / FLOAT
     / FnProto
     / GroupedExpr
     / LabeledTypeExpr
     / IDENTIFIER
     / IfTypeExpr
     / INTEGER
     / KEYWORD_comptime TypeExpr
     / KEYWORD_error DOT IDENTIFIER
     / KEYWORD_anyframe
     / KEYWORD_unreachable
     / STRINGLITERAL
     / SwitchExpr

ContainerDecl <- (KEYWORD_extern / KEYWORD_packed)? ContainerDeclAuto

ErrorSetDecl <- KEYWORD_error LBRACE IdentifierList RBRACE

GroupedExpr <- LPAREN Expr RPAREN

IfTypeExpr <- IfPrefix TypeExpr (KEYWORD_else Payload? TypeExpr)?

LabeledTypeExpr
    <- BlockLabel Block
     / BlockLabel? LoopTypeExpr

LoopTypeExpr <- KEYWORD_inline? (ForTypeExpr / WhileTypeExpr)

ForTypeExpr <- ForPrefix TypeExpr (KEYWORD_else TypeExpr)?

WhileTypeExpr <- WhilePrefix TypeExpr (KEYWORD_else Payload? TypeExpr)?

SwitchExpr <- KEYWORD_switch LPAREN Expr RPAREN LBRACE SwitchProngList RBRACE

# *** Assembly ***
AsmExpr <- KEYWORD_asm KEYWORD_volatile? LPAREN Expr AsmOutput? RPAREN

AsmOutput <- COLON AsmOutputList AsmInput?

AsmOutputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN (MINUSRARROW TypeExpr / IDENTIFIER) RPAREN

AsmInput <- COLON AsmInputList AsmClobbers?

AsmInputItem <- LBRACKET IDENTIFIER RBRACKET STRINGLITERAL LPAREN Expr RPAREN

AsmClobbers <- COLON StringList

# *** Helper grammar ***
BreakLabel <- COLON IDENTIFIER

BlockLabel <- IDENTIFIER COLON

FieldInit <- DOT IDENTIFIER EQUAL Expr

WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN

LinkSection <- KEYWORD_linksection LPAREN Expr RPAREN

AddrSpace <- KEYWORD_addrspace LPAREN Expr RPAREN

# Fn specific
CallConv <- KEYWORD_callconv LPAREN Expr RPAREN

ParamDecl
    <- doc_comment? (KEYWORD_noalias / KEYWORD_comptime)? (IDENTIFIER COLON)? ParamType
     / DOT3

ParamType
    <- KEYWORD_anytype
     / TypeExpr

# Control flow prefixes
IfPrefix <- KEYWORD_if LPAREN Expr RPAREN PtrPayload?

WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?

ForPrefix <- KEYWORD_for LPAREN ForArgumentsList RPAREN PtrListPayload

# Payloads
Payload <- PIPE IDENTIFIER PIPE

PtrPayload <- PIPE ASTERISK? IDENTIFIER PIPE

PtrIndexPayload <- PIPE ASTERISK? IDENTIFIER (COMMA IDENTIFIER)? PIPE

PtrListPayload <- PIPE ASTERISK? IDENTIFIER (COMMA ASTERISK? IDENTIFIER)* COMMA? PIPE

# Switch specific
SwitchProng <- KEYWORD_inline? SwitchCase EQUALRARROW PtrIndexPayload? SingleAssignExpr

SwitchCase
    <- SwitchItem (COMMA SwitchItem)* COMMA?
     / KEYWORD_else

SwitchItem <- Expr (DOT3 Expr)?

# For specific
ForArgumentsList <- ForItem (COMMA ForItem)* COMMA?

ForItem <- Expr (DOT2 Expr?)?

# Operators
AssignOp
    <- ASTERISKEQUAL
     / ASTERISKPIPEEQUAL
     / SLASHEQUAL
     / PERCENTEQUAL
     / PLUSEQUAL
     / PLUSPIPEEQUAL
     / MINUSEQUAL
     / MINUSPIPEEQUAL
     / LARROW2EQUAL
     / LARROW2PIPEEQUAL
     / RARROW2EQUAL
     / AMPERSANDEQUAL
     / CARETEQUAL
     / PIPEEQUAL
     / ASTERISKPERCENTEQUAL
     / PLUSPERCENTEQUAL
     / MINUSPERCENTEQUAL
     / EQUAL

CompareOp
    <- EQUALEQUAL
     / EXCLAMATIONMARKEQUAL
     / LARROW
     / RARROW
     / LARROWEQUAL
     / RARROWEQUAL

BitwiseOp
    <- AMPERSAND
     / CARET
     / PIPE
     / KEYWORD_orelse
     / KEYWORD_catch Payload?

BitShiftOp
    <- LARROW2
     / RARROW2
     / LARROW2PIPE

AdditionOp
    <- PLUS
     / MINUS
     / PLUS2
     / PLUSPERCENT
     / MINUSPERCENT
     / PLUSPIPE
     / MINUSPIPE

MultiplyOp
    <- PIPE2
     / ASTERISK
     / SLASH
     / PERCENT
     / ASTERISK2
     / ASTERISKPERCENT
     / ASTERISKPIPE

PrefixOp
    <- EXCLAMATIONMARK
     / MINUS
     / TILDE
     / MINUSPERCENT
     / AMPERSAND
     / KEYWORD_try
     / KEYWORD_await

PrefixTypeOp
    <- QUESTIONMARK
     / KEYWORD_anyframe MINUSRARROW
     / SliceTypeStart (ByteAlign / AddrSpace / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
     / PtrTypeStart (AddrSpace / KEYWORD_align LPAREN Expr (COLON Expr COLON Expr)? RPAREN / KEYWORD_const / KEYWORD_volatile / KEYWORD_allowzero)*
     / ArrayTypeStart

SuffixOp
    <- LBRACKET Expr (DOT2 (Expr? (COLON Expr)?)?)? RBRACKET
     / DOT IDENTIFIER
     / DOTASTERISK
     / DOTQUESTIONMARK

FnCallArguments <- LPAREN ExprList RPAREN

# Ptr specific
SliceTypeStart <- LBRACKET (COLON Expr)? RBRACKET

PtrTypeStart
    <- ASTERISK
     / ASTERISK2
     / LBRACKET ASTERISK (LETTERC / COLON Expr)? RBRACKET

ArrayTypeStart <- LBRACKET Expr (COLON Expr)? RBRACKET

# ContainerDecl specific
ContainerDeclAuto <- ContainerDeclType LBRACE container_doc_comment? ContainerMembers RBRACE

ContainerDeclType
    <- KEYWORD_struct (LPAREN Expr RPAREN)?
     / KEYWORD_opaque
     / KEYWORD_enum (LPAREN Expr RPAREN)?
     / KEYWORD_union (LPAREN (KEYWORD_enum (LPAREN Expr RPAREN)? / Expr) RPAREN)?

# Alignment
ByteAlign <- KEYWORD_align LPAREN Expr RPAREN

# Lists
IdentifierList <- (doc_comment? IDENTIFIER COMMA)* (doc_comment? IDENTIFIER)?

SwitchProngList <- (SwitchProng COMMA)* SwitchProng?

AsmOutputList <- (AsmOutputItem COMMA)* AsmOutputItem?

AsmInputList <- (AsmInputItem COMMA)* AsmInputItem?

StringList <- (STRINGLITERAL COMMA)* STRINGLITERAL?

ParamDeclList <- (ParamDecl COMMA)* ParamDecl?

ExprList <- (Expr COMMA)* Expr?

# *** Tokens ***
eof <- !.
bin <- [01]
bin_ <- '_'? bin
oct <- [0-7]
oct_ <- '_'? oct
hex <- [0-9a-fA-F]
hex_ <- '_'? hex
dec <- [0-9]
dec_ <- '_'? dec

bin_int <- bin bin_*
oct_int <- oct oct_*
dec_int <- dec dec_*
hex_int <- hex hex_*

ox80_oxBF <- [\200-\277]
oxF4 <- '\364'
ox80_ox8F <- [\200-\217]
oxF1_oxF3 <- [\361-\363]
oxF0 <- '\360'
ox90_0xBF <- [\220-\277]
oxEE_oxEF <- [\356-\357]
oxED <- '\355'
ox80_ox9F <- [\200-\237]
oxE1_oxEC <- [\341-\354]
oxE0 <- '\340'
oxA0_oxBF <- [\240-\277]
oxC2_oxDF <- [\302-\337]

# From https://lemire.me/blog/2018/05/09/how-quickly-can-you-check-that-a-string-is-valid-unicode-utf-8/
# First Byte      Second Byte     Third Byte      Fourth Byte
# [0x00,0x7F]
# [0xC2,0xDF]     [0x80,0xBF]
#    0xE0         [0xA0,0xBF]     [0x80,0xBF]
# [0xE1,0xEC]     [0x80,0xBF]     [0x80,0xBF]
#    0xED         [0x80,0x9F]     [0x80,0xBF]
# [0xEE,0xEF]     [0x80,0xBF]     [0x80,0xBF]
#    0xF0         [0x90,0xBF]     [0x80,0xBF]     [0x80,0xBF]
# [0xF1,0xF3]     [0x80,0xBF]     [0x80,0xBF]     [0x80,0xBF]
#    0xF4         [0x80,0x8F]     [0x80,0xBF]     [0x80,0xBF]

mb_utf8_literal <-
       oxF4      ox80_ox8F ox80_oxBF ox80_oxBF
     / oxF1_oxF3 ox80_oxBF ox80_oxBF ox80_oxBF
     / oxF0      ox90_0xBF ox80_oxBF ox80_oxBF
     / oxEE_oxEF ox80_oxBF ox80_oxBF
     / oxED      ox80_ox9F ox80_oxBF
     / oxE1_oxEC ox80_oxBF ox80_oxBF
     / oxE0      oxA0_oxBF ox80_oxBF
     / oxC2_oxDF ox80_oxBF

ascii_char_not_nl_slash_squote <- [\000-\011\013-\046\050-\133\135-\177]

char_escape
    <- "\\x" hex hex
     / "\\u{" hex+ "}"
     / "\\" [nr\\t'"]
char_char
    <- mb_utf8_literal
     / char_escape
     / ascii_char_not_nl_slash_squote

string_char
    <- char_escape
     / [^\\"\n]

container_doc_comment <- ('//!' [^\n]* [ \n]* skip)+
doc_comment <- ('///' [^\n]* [ \n]* skip)+
line_comment <- '//' ![!/][^\n]* / '////' [^\n]*
line_string <- ("\\\\" [^\n]* [ \n]*)+
skip <- ([ \n] / line_comment)*

CHAR_LITERAL <- "'" char_char "'" skip
FLOAT
    <- "0x" hex_int "." hex_int ([pP] [-+]? dec_int)? skip
     /      dec_int "." dec_int ([eE] [-+]? dec_int)? skip
     / "0x" hex_int [pP] [-+]? dec_int skip
     /      dec_int [eE] [-+]? dec_int skip
INTEGER
    <- "0b" bin_int skip
     / "0o" oct_int skip
     / "0x" hex_int skip
     /      dec_int   skip
STRINGLITERALSINGLE <- "\"" string_char* "\"" skip
STRINGLITERAL
    <- STRINGLITERALSINGLE
     / (line_string                 skip)+
IDENTIFIER
    <- !keyword [A-Za-z_] [A-Za-z0-9_]* skip
     / "@" STRINGLITERALSINGLE
BUILTINIDENTIFIER <- "@"[A-Za-z_][A-Za-z0-9_]* skip


AMPERSAND            <- '&'      ![=]      skip
AMPERSANDEQUAL       <- '&='               skip
ASTERISK             <- '*'      ![*%=|]   skip
ASTERISK2            <- '**'               skip
ASTERISKEQUAL        <- '*='               skip
ASTERISKPERCENT      <- '*%'     ![=]      skip
ASTERISKPERCENTEQUAL <- '*%='              skip
ASTERISKPIPE         <- '*|'     ![=]      skip
ASTERISKPIPEEQUAL    <- '*|='              skip
CARET                <- '^'      ![=]      skip
CARETEQUAL           <- '^='               skip
COLON                <- ':'                skip
COMMA                <- ','                skip
DOT                  <- '.'      ![*.?]    skip
DOT2                 <- '..'     ![.]      skip
DOT3                 <- '...'              skip
DOTASTERISK          <- '.*'               skip
DOTQUESTIONMARK      <- '.?'               skip
EQUAL                <- '='      ![>=]     skip
EQUALEQUAL           <- '=='               skip
EQUALRARROW          <- '=>'               skip
EXCLAMATIONMARK      <- '!'      ![=]      skip
EXCLAMATIONMARKEQUAL <- '!='               skip
LARROW               <- '<'      ![<=]     skip
LARROW2              <- '<<'     ![=|]     skip
LARROW2EQUAL         <- '<<='              skip
LARROW2PIPE          <- '<<|'    ![=]      skip
LARROW2PIPEEQUAL     <- '<<|='             skip
LARROWEQUAL          <- '<='               skip
LBRACE               <- '{'                skip
LBRACKET             <- '['                skip
LPAREN               <- '('                skip
MINUS                <- '-'      ![%=>|]   skip
MINUSEQUAL           <- '-='               skip
MINUSPERCENT         <- '-%'     ![=]      skip
MINUSPERCENTEQUAL    <- '-%='              skip
MINUSPIPE            <- '-|'     ![=]      skip
MINUSPIPEEQUAL       <- '-|='              skip
MINUSRARROW          <- '->'               skip
PERCENT              <- '%'      ![=]      skip
PERCENTEQUAL         <- '%='               skip
PIPE                 <- '|'      ![|=]     skip
PIPE2                <- '||'               skip
PIPEEQUAL            <- '|='               skip
PLUS                 <- '+'      ![%+=|]   skip
PLUS2                <- '++'               skip
PLUSEQUAL            <- '+='               skip
PLUSPERCENT          <- '+%'     ![=]      skip
PLUSPERCENTEQUAL     <- '+%='              skip
PLUSPIPE             <- '+|'     ![=]      skip
PLUSPIPEEQUAL        <- '+|='              skip
LETTERC              <- 'c'                skip
QUESTIONMARK         <- '?'                skip
RARROW               <- '>'      ![>=]     skip
RARROW2              <- '>>'     ![=]      skip
RARROW2EQUAL         <- '>>='              skip
RARROWEQUAL          <- '>='               skip
RBRACE               <- '}'                skip
RBRACKET             <- ']'                skip
RPAREN               <- ')'                skip
SEMICOLON            <- ';'                skip
SLASH                <- '/'      ![=]      skip
SLASHEQUAL           <- '/='               skip
TILDE                <- '~'                skip

end_of_word <- ![a-zA-Z0-9_] skip
KEYWORD_addrspace   <- 'addrspace'   end_of_word
KEYWORD_align       <- 'align'       end_of_word
KEYWORD_allowzero   <- 'allowzero'   end_of_word
KEYWORD_and         <- 'and'         end_of_word
KEYWORD_anyframe    <- 'anyframe'    end_of_word
KEYWORD_anytype     <- 'anytype'     end_of_word
KEYWORD_asm         <- 'asm'         end_of_word
KEYWORD_async       <- 'async'       end_of_word
KEYWORD_await       <- 'await'       end_of_word
KEYWORD_break       <- 'break'       end_of_word
KEYWORD_callconv    <- 'callconv'    end_of_word
KEYWORD_catch       <- 'catch'       end_of_word
KEYWORD_comptime    <- 'comptime'    end_of_word
KEYWORD_const       <- 'const'       end_of_word
KEYWORD_continue    <- 'continue'    end_of_word
KEYWORD_defer       <- 'defer'       end_of_word
KEYWORD_else        <- 'else'        end_of_word
KEYWORD_enum        <- 'enum'        end_of_word
KEYWORD_errdefer    <- 'errdefer'    end_of_word
KEYWORD_error       <- 'error'       end_of_word
KEYWORD_export      <- 'export'      end_of_word
KEYWORD_extern      <- 'extern'      end_of_word
KEYWORD_fn          <- 'fn'          end_of_word
KEYWORD_for         <- 'for'         end_of_word
KEYWORD_if          <- 'if'          end_of_word
KEYWORD_inline      <- 'inline'      end_of_word
KEYWORD_noalias     <- 'noalias'     end_of_word
KEYWORD_nosuspend   <- 'nosuspend'   end_of_word
KEYWORD_noinline    <- 'noinline'    end_of_word
KEYWORD_opaque      <- 'opaque'      end_of_word
KEYWORD_or          <- 'or'          end_of_word
KEYWORD_orelse      <- 'orelse'      end_of_word
KEYWORD_packed      <- 'packed'      end_of_word
KEYWORD_pub         <- 'pub'         end_of_word
KEYWORD_resume      <- 'resume'      end_of_word
KEYWORD_return      <- 'return'      end_of_word
KEYWORD_linksection <- 'linksection' end_of_word
KEYWORD_struct      <- 'struct'      end_of_word
KEYWORD_suspend     <- 'suspend'     end_of_word
KEYWORD_switch      <- 'switch'      end_of_word
KEYWORD_test        <- 'test'        end_of_word
KEYWORD_threadlocal <- 'threadlocal' end_of_word
KEYWORD_try         <- 'try'         end_of_word
KEYWORD_union       <- 'union'       end_of_word
KEYWORD_unreachable <- 'unreachable' end_of_word
KEYWORD_usingnamespace <- 'usingnamespace' end_of_word
KEYWORD_var         <- 'var'         end_of_word
KEYWORD_volatile    <- 'volatile'    end_of_word
KEYWORD_while       <- 'while'       end_of_word

keyword <- KEYWORD_addrspace / KEYWORD_align / KEYWORD_allowzero / KEYWORD_and
         / KEYWORD_anyframe / KEYWORD_anytype / KEYWORD_asm / KEYWORD_async
         / KEYWORD_await / KEYWORD_break / KEYWORD_callconv / KEYWORD_catch
         / KEYWORD_comptime / KEYWORD_const / KEYWORD_continue / KEYWORD_defer
         / KEYWORD_else / KEYWORD_enum / KEYWORD_errdefer / KEYWORD_error / KEYWORD_export
         / KEYWORD_extern / KEYWORD_fn / KEYWORD_for / KEYWORD_if
         / KEYWORD_inline / KEYWORD_noalias / KEYWORD_nosuspend / KEYWORD_noinline
         / KEYWORD_opaque / KEYWORD_or / KEYWORD_orelse / KEYWORD_packed
         / KEYWORD_pub / KEYWORD_resume / KEYWORD_return / KEYWORD_linksection
         / KEYWORD_struct / KEYWORD_suspend / KEYWORD_switch / KEYWORD_test
         / KEYWORD_threadlocal / KEYWORD_try / KEYWORD_union / KEYWORD_unreachable
         / KEYWORD_usingnamespace / KEYWORD_var / KEYWORD_volatile / KEYWORD_while