import Node, Type, Declaration, Expression, VariableAccess, BaseType

import structs/HashMap

TypeArgKind: enum {
    Generic,
    Template,
    Unknown

    toString: func -> String {
        match this {
            case This Generic  => "Generic"
            case This Template => "Template"
            case               => "Unknown"
        }
    }
}

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

    toString: func -> String {
        "TypeArg##{index}(#{kind})"
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        raise("Internal compiler error: cannot call replace on #{this}")
        false
    }

    clone: func -> This {
        This new(index, kind, token)
    }
}

/**
 * A type arg decl is the original declaration of a type arg.
 * It has a name that is only used in the code generation phase
 * and a type arg which is its position in the original declaration and
 * the kind it was declared as.
 */

TypeArgDecl: class extends Declaration {
    owner: Declaration

    originalName: String
    typeArg: TypeArg

    init: func (=owner, =originalName, =typeArg, .token) {
        super(token)
    }

    toString: func -> String {
        "#{owner} <#{originalName}##{index}(#{kind})>"
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        raise("Internal compiler error: cannot call replace on #{this}")
        false
    }

    clone: func -> This {
        // TODO: Should we clone the owner?
        // Seems like a bad thing to do.
        This new(owner, originalName clone(), typeArg clone())
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

    init: func ~completeTArg (=typeArg, =type, .token) {
        super(token)
    }

    init: func ~argAndRef (=typeArg, =type, =ref, .token) {
        super(token)
    }

    toString: func -> String {
        match ref {
            case null =>
                "##{typeArg index}(#{typeArg kind}): #{type}"
            case      =>
                "#{ref}: #{type}"
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        if (oldie == type) {
            type = kiddo as Type
            true
        } else {
            false
        }
    }

    clone: func -> This {
        This new(typeArg clone(), type clone(), ref clone(), token)
    }
}

/**
 * A type arg map is a map of names to type args.
 * It is used to overwrite the names of type args
 * by things like Addons or TypeDecls (overwritting
 * to their supertypes)
 */

TypeArgMap: class extends HashMap<String, TypeArgDecl> {

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

    toString: func -> String {
        match ref {
            case null =>
                "#{name}"
            case      =>
                "#{name} => #{ref}"
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        raise("Internal compiler error: cannot call replace on #{this}")
        false
    }

    clone: func -> This {
        new := This new(from, token)
        new name = name clone()
        new ref = ref clone()
        new
    }

    getType: func -> Type {
        BaseType new("Class", token)
    }

    isReferencable: func -> Bool { true }
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

    toString: func -> String {
        match ref {
            case null =>
                "#{name}"
            case      =>
                "#{name} => #{ref}"
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        raise("Internal compiler error: cannot call replace on #{this}")
        false
    }

    clone: func -> This {
        new := This new(from, token)
        new name = name clone()
        new
    }

    getRef: func -> TypeArgDecl {
        ref
    }

    setRef: func (=ref)

    isGeneric: func -> Bool {
        if (ref) {
            ref kind == TypeArgKind Generic
        } else {
            false
        }
    }

    pointerLevel: func -> Int {
        0
    }

    equals?: func (other: Type) -> Bool {
        if (other class != class) {
            false
        } else {
            match (other ref) {
                case ref => true
                case     => false
            }
        }
    }

    getName: func -> String {
        name
    }

    dereference: func -> Type {
        null
    }

    getType: func -> This { cloneWithRef() }

    getScoreImpl: func (other: This, scoreSeed: Int) -> Int {
        match other {
            case tat: TypeArgType =>
                // TODO: what about template vs template?
                return scoreSeed
            case =>
                if (isGeneric()) {
                    if (other pointerLevel() == 0) {
                        return scoreSeed
                    } else if (other isPointer()) {
                        return scoreSeed / 2
                    }
                } else {
                    return scoreSeed
                }
        }

        // How am I here?
        This NOLUCK_SCORE
    }

    dig: func -> Type {
        null
    }

    checkedDigImpl: func (list: List<Type>, res: Resolver)
}
