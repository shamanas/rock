import ../frontend/Token
import [Type, Expression, VariableAccess, Comparison, Ternary, VariableDecl, CommaSequence, BinaryOp,
        FunctionCall, BinaryOp, Parenthesis, NullLiteral, Visitor, Node]

import tinker/[Resolver, Response, Trail, Errors]
import structs/ArrayList

SafeNavigation: class extends Expression {
    expr: Expression

    // Sections are expressions that are mixes of variable accesses and method calls
    sections := ArrayList<Expression> new()

    _resolved? := false

    init: func (=expr, token: Token) {
        super(token)
    }

    // We replace ourselves, no need to return any type
    getType: func -> Type { null }

    clone: func -> This {
        other := This new(expr clone(), token)
        other sections = sections clone()
        other
    }

    // Checks wether the fCall/vAccess chain has at least one fCall in it
    _hasSideEffects: func (e: Expression) -> Bool {
        curr := e
        while (curr) {
            match curr {
                case f: FunctionCall =>
                    return true
                case va: VariableAccess =>
                    curr = va expr
            }
        }
        false
    }

    // Takes an expression, makes a decl for it and returns an expression that assigns to it and the access to it
    _makeDecl: func (e: Expression, trail: Trail, res: Resolver) -> (Expression, Expression) {
        decl := VariableDecl new~inferTypeOnly(null, generateTempName("safeNavExpr"), e, token)
        vacc := VariableAccess new(decl, token)

        if (!trail addBeforeInScope(this, decl)) {
            res throwError(CouldntAddBeforeInScope new(token, this, decl, trail))
            return (null, null)
        }

        bop := Parenthesis new(BinaryOp new(vacc, e, OpType ass, token), token)
        (bop, vacc)
    }

    // Correctly adds the child to the beginning of the fCall/vAccess chain
    _chain: func (base: Expression, child: Expression) {
        curr := base

        while (true) {
            match curr {
                case va: VariableAccess =>
                    if (va expr != null) {
                        curr = va expr
                    } else {
                        break
                    }
                case fc: FunctionCall =>
                    if (fc expr != null) {
                        curr = fc expr
                    } else {
                        break
                    }
                // Wat.
                case => break
            }
        }

        match curr {
            case va: VariableAccess =>
                va expr = child
            case fc: FunctionCall =>
                fc expr = child
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        if (_resolved?) return Response OK

        trail push(this)
        resp := expr resolve(trail, res)
        if (!resp ok()) {
            trail pop(this)
            return resp
        }
        trail pop(this)

        if (!expr getType()) {
            res wholeAgain(this, "need type of safe navigation access expression")
            return Response OK
        }

        // We need to avoid multiple evaluation of the expression, so we will use a variable declaration and assign it in a comma list before this
        vDecl := VariableDecl new(expr getType(), generateTempName("safeNavExpr"), token)
        vAccess := VariableAccess new(vDecl, token)

        if (!trail addBeforeInScope(this, vDecl)) {
            res throwError(CouldntAddBeforeInScope new(token, this, vDecl, trail))
            return Response OK
        }

        seq := CommaSequence new(token)
        assignment := BinaryOp new(vAccess, expr, OpType ass, token)

        seq add(assignment)


        // So, we need to iterate through the sections and build a single fCall or vAccess that will show up in the ternary operator chain
        // For example, something like that: expr $ a b() c $ d $ e f()
        // Will generate this list: [ expr a b() c, expr a b() c d, expr a b() c d e f() ]
        // Of course, to avoid side effects, we generate temporary variables when needed (when we have function calls)
        lastExpr : Expression = vAccess
        exprs := ArrayList<Expression> new()
        for (current in sections) {
            _chain(current, lastExpr)

            if (_hasSideEffects(current)) {
                (assign, acc) := _makeDecl(current, trail, res)
                exprs add(assign)
                lastExpr = acc
            } else {
                exprs add(current)
                lastExpr = current
            }
        }

        localNull := NullLiteral new(token)

        makeNotEquals := func(e: Expression) -> Comparison {
            Comparison new(e, localNull, CompType notEqual, token)
        }

        makeTernary := func(cond: Comparison, e: Expression) -> Ternary {
            Ternary new(cond, e, localNull, token)
        }

        // We don't need to generate a ternary for the last access.
        // 'foo != null ? foo : null' is equivalent to 'foo'
        iterator := exprs backIterator()
        curr : Expression = iterator prev()

        while (iterator hasPrev?()) {
            access := iterator prev()

            curr = makeTernary(makeNotEquals(access), curr)
        }

        curr = makeTernary(makeNotEquals(vAccess), curr)

        seq add(curr)

        if (!trail peek() replace(this, seq)) {
            res throwError(CouldntReplace new(token, this, seq, trail))
            return Response OK
        }

        _resolved? = true

        res wholeAgain(this, "replaced safe navigation access with comma sequence")
        Response OK
    }

    toString: func -> String {
        buff := Buffer new()
        buff append(expr toString())

        for (sec in sections) {
            buff append(" $ #{sec}")
        }

        buff toString()
    }

    accept: func(visitor: Visitor)

    replace: func(oldie: Node, kiddo: Node) -> Bool {
        match oldie {
            case e: Expression =>
                if (e == expr) {
                    expr = kiddo as Expression
                    return true
                }
        }

        false
    }

    isResolved: func -> Bool {
        _resolved?
    }
}
