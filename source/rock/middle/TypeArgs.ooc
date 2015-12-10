import Node, Type, Declaration, Expression, VariableAccess, BaseType

import structs/HashMap

TypeArgKind: enum {
    Generic,
    Template,
    Unknown
}

// TODO: TypeArgType


/**
 * A type arg is, simply put, a pair of an index and a kind.
 * It symbolizes a position in a list of anything related to type args.
 */

TypeArg: class extends Node {
    index: Int
    kind: TypeArgKind

    init: func (=index, =kind, .token) {
        super(token)
    }
}

/**
 * A type arg decl is the original declaration of a type arg.
 * It has a name that is only used in the code generation phase
 * and a type arg which is its position in the original declaration and
 * the kind it was declared as.
 */

TypeArgDecl: class extends Node {
    originalName: String
    typeArg: TypeArg

    init: func (=originalName, =typeArg, .token) {
        super(token)
    }
}

/**
 * A type arg instance is the link between a type arg position
 * and the real type it finally takes.
 * It is commonly held by BaseTypes and can be calculated for
 * things like function calls (most commonly)
 */

TypeArgInstance: class extends Node {
    typeArg: TypeArg
    ref: TypeArgDecl

    type: Type

    init: func (index: Int, =type, .token) {
        typeArg = TypeArg new(index, TypeArgKind Unknown)
        super(token)
    }
}

/**
 * A type arg map is a map of names to type args.
 * It is used to overwrite the names of type args
 * by things like Addons or TypeDecls (overwritting
 * to their supertypes
 */

TypeArgMap: class extends HashMap<String, TypeArg> {

}

/**
 * A type arg access is an access to a type arg in
 * an expression context.
 * It is typically generated from a VariableAccess
 * and replaced in its place.
 * It has a name like it was originally referred to
 * and a type arg declaration reference.
 */

TypeArgAccess: class extends Expression {
    from: VariableAccess

    name: String
    ref: TypeArgDecl

    init: func ~fromVAcc (=from, .token) {
        name = from name
        super(token)
    }

    init: func ~withName (=name, .token) {
        super(token)
    }
}

/**
 * A type arg type is to a BaseType what a
 * type arg access is to a VariableAccess.
 */

TypeArgType: class extends Type {
    from: BaseType

    name: String
    ref: TypeArgDecl

    init: func ~fromBType (=from, .token) {
        name = from name
        super(token)
    }

    init: func ~withName (=name, .token) {
        super(token)
    }
}
