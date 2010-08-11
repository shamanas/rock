import structs/ArrayList
import ../frontend/[Token, BuildParams]
import Expression, Visitor, Type, Node, VariableDecl, FunctionDecl
import tinker/[Trail, Resolver, Response]

AddressOf: class extends Expression {

    expr: Expression
    isForGenerics := false // hack - see FunctionCall handleGenerics()

    init: func ~addressOf (=expr, .token) {
        super(token)
    }

    clone: func -> This {
        copy := new(expr, token)
        copy isForGenerics = isForGenerics // not that this should never be needed.
        copy
    }

    accept: func (visitor: Visitor) {
        visitor visitAddressOf(this)
    }

    hasSideEffects : func -> Bool { expr hasSideEffects() }

    getType: func -> Type { expr getType() ? expr getType() reference() : null }

    toString: func -> String {
        return expr toString() + "&"
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        trail push(this)
        {
            response := expr resolve(trail, res)
            if(!response ok()) {
                trail pop(this)
                return response
            }
        }
        trail pop(this)

        if(!expr isReferencable()) {
            expr = VariableDecl new(null, generateTempName("unreferencable"), expr, expr token)
            res wholeAgain(this, "replaced expr with varDecl, need to unwrap")
        }

        return Responses OK

    }

    replace: func (oldie, kiddo: Node) -> Bool {
        match oldie {
            case expr => expr = kiddo; true
            case      => false
        }
    }

}
