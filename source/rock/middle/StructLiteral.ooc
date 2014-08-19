import ../frontend/[Token, BuildParams]
import ../backend/cnaughty/AwesomeWriter
import Literal, Visitor, Type, Expression, Node, TypeList, Tuple, BaseType,
       Declaration, FunctionCall, VariableAccess, CoverDecl, Statement
import tinker/[Response, Resolver, Trail]
import structs/[List, ArrayList]

StructLiteral: class extends Tuple {

    realType : Type = null

    init: func ~structLiteral (=realType, =elements, .token) {
        super(token)
    }

    accept: func (visitor: Visitor) {
        visitor visitStructLiteral(this)
    }

    getType: func -> Type {
        realType
    }

}

anonStructUniversalType := CoverDecl new("<anon struct>", nullToken)

StructDecl: class extends Statement {
    types := ArrayList<Type> new()

    name: String
    _type: Type

    init: func

    init: func ~structDecl (=name, .token) {
        super(token)

        _type = BaseType new("struct #{name}", token)
    }


    resolve: func (trail: Trail, res: Resolver) -> Response {
        types each(|type|
            type resolve(trail, res)
        )

        Response OK
    }

    getType: func -> Type {
        _type
    }

    write: func (w: AwesomeWriter, _: String) {
        counter := 1
        w app("struct #{name} { "). tab()
        types each(|t|
            w nl(). app(t). app(" __f"). app(counter toString()). app(";")
            counter += 1
        )
        w untab(). nl(). app("};"). nl()
    }

    accept: func(visitor: Visitor) {
        visitor visitStructDecl(this)
    }

    replace: func(oldie, kiddo: Node) -> Bool { false }

    clone: func -> This {
        This new(name, token)
    }
}

AnonymousStructType: class extends Type {

    types := ArrayList<Type> new()

    init: super func ~type

    pointerLevel: func -> Int { 0 }

    getName: func -> String { "<anon struct>" }
    getRef: func -> Declaration { anonStructUniversalType }
    setRef: func (d: Declaration) { raise("Setting ref of an anonymous struct type!") }

    realTypize: func (call: FunctionCall) -> Type { this }
    clone: func -> This { this }
    
    dig: func -> Type { this }
    checkedDigImpl: func (list: List<Type>, res: Resolver) {}
    
    dereference: func -> Type { raise("Dereferencing an anonymous struct type"); null }
    getTypeArgs: func -> List<VariableAccess> { null }

    equals?: func (t: Type) -> Bool {
        if(t class != class) return false
        other := t as This
        if(other types size != types size) return false
        for(i in 0..types size) {
            if(!other types[i] equals?(types[i])) return false
        }
        true
    }

    getScoreImpl: func (other: This, scoreSeed: Int) -> Int {
        0
    }

    write: func (w: AwesomeWriter, name: String) {
        counter := 1
        w app("struct { "). tab()
        types each(|t|
            w nl(). app(t). app(" __f"). app(counter toString()). app(";")
            counter += 1
        )
        w untab(). nl(). app("} ")
        if(name) w app(name)
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {
        types each(|type|
            type resolve(trail, res)
        )
        
        Response OK
    }

}


