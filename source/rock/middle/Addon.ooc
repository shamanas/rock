import structs/[ArrayList, HashMap, MultiMap]
import Node, Type, TypeDecl, FunctionDecl, FunctionCall, Visitor, VariableAccess, PropertyDecl, ClassDecl, CoverDecl, BaseType
import tinker/[Trail, Resolver, Response, Errors]

/**
 * An addon is a collection of methods added to a type via the 'extend'
 * keyword, like so:
 *
 * extend Mortal {
 *    killViolently: func { scream(); die() }
 * }
 *
 * In ooc, classes aren't open like in Rooby. We're not in a little pink
 * world where all fields and methods are hashmap values. So we're just
 * pretending they're member functions - but really, they'll only be available
 * to modules importing the module containing the 'extend' clause.
 */
Addon: class extends Node {

    doc: String = null

    // the type we're adding functions to
    baseType: Type

    typeArgs: List<TypeAccess> = null

    base: TypeDecl { get set }

    functions := MultiMap<String, FunctionDecl> new()

    properties := HashMap<String, PropertyDecl> new()

    init: func (=baseType, .token) {
        super(token)

        // If we try to extend a type with typeArgs, we are obviously trying to extend it generically
        if (baseType typeArgs) {
            typeArgs = baseType typeArgs
            baseType typeArgs = null
        }
    }

    accept: func (v: Visitor) {
        for(f in functions) {
            f accept(v)
        }
    }

    replace: func (oldie, kiddo: Node) -> Bool {
        false
    }

    clone: func -> This {
        Exception new(This, "Cloning of addons isn't supported")
        null
    }

    // all functions of an addon are final, because we *definitely* don't have a 'class' field
    addFunction: func (fDecl: FunctionDecl) {
        fDecl isFinal = true

        // TODO: check for redefinitions...
        functions put(fDecl getName(), fDecl)
    }

    addProperty: func (vDecl: PropertyDecl) {
        properties put(vDecl name, vDecl)
    }
    
    lookupFunction: func (fName: String, fSuffix: String = null) -> FunctionDecl {
        result: FunctionDecl
        functions getEachUntil(fName, |fDecl|
            if (fSuffix == null || fDecl getSuffixOrEmpty() == fSuffix){
                result = fDecl
                return false
            }
            true
        )
        result
    }

    checkRedefinitions: func(trail: Trail, res: Resolver){
        // Base unresolved, can not check
        if(base == null) return

        for(fDecl in functions){
            bother : FunctionDecl 
            if(!base isMeta){
                bother = base meta lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
            } else {
                bother = base lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
            }
            if(bother != null) res throwError(FunctionRedefinition new(fDecl, bother))
            for(addon in base getAddons()){
                other := addon lookupFunction(fDecl getName(), fDecl getSuffixOrEmpty())
                if(other != null) res throwError(FunctionRedefinition new(fDecl, other))
            }
        }
    }

    resolve: func (trail: Trail, res: Resolver) -> Response {

        // Let's check that we got all BaseTypes, in any other case something is really fishy here
        if (typeargs) for (ta in typeArgs) {
            match (ta inner) {
                case bt: BaseType =>
                case =>
                    res throwError(InvalidTypeargType new(ta token,
                                        "Unexpected typearg in extend definition.\n\n(Hint: remember you are extending the whole class, not specializing it)"))
            }
        }

        if(base == null) {
            baseType resolve(trail, res)
            if(baseType isResolved()) {
                // First of all, check we have the correct amount of typeArgs.
                if (typeArgs) {
                    ourSize := typeArgs getSize()
                    baseSize := baseType typeArgs getSize()

                    if (ourSize != baseSize) {
                        res throwError(InvalidGenericExtention new(token,
                                    "Trying to extend class with incorrect amount of typeargs. (Expected #{baseSize}, got #{ourSize})"))
                    }
                }

                base = baseType getRef() as TypeDecl
                checkRedefinitions(trail, res)
                base addons add(this)

                for(fDecl in functions) {
                    if(fDecl name == "init" && (base instanceOf?(ClassDecl) || base instanceOf?(CoverDecl))) {
                        if(base instanceOf?(ClassDecl)) base as ClassDecl addInit(fDecl)
                        else base getMeta() addInit(fDecl)
                    }
                    fDecl setOwner(base)
                }

                for(prop in properties) {
                    old := base getVariable(prop name)
                    if(old) token module params errorHandler onError(DuplicateField new(old, prop))
                    prop owner = base
                }
            } else {
                res wholeAgain(this, "need baseType ref")
            }
        }

        if(base == null) {
            res wholeAgain(this, "need base")
            return Response OK
        }

        finalResponse := Response OK
        trail push(base getMeta())
        for(f in functions) {
            response := f resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            }
        }
        for(p in properties) {
            response := p resolve(trail, res)
            if(!response ok()) {
                finalResponse = response
            } else {
                // all functions of an addon are final, because we *definitely* don't have a 'class' field
                if(p getter) p getter isFinal = true
                if(p setter) p setter isFinal = true
            }
        }
        trail pop(base getMeta())

        return finalResponse
    }

    resolveCall: func (call : FunctionCall, res: Resolver, trail: Trail) -> Int {
        if(base == null) return 0

        functions getEach(call name, |fDecl|
            if (call suffix && fDecl suffix != call suffix) {
                // skip it! till you make it.
                return
            }

            if (call suggest(fDecl, res, trail)) {
                if (fDecl hasThis() && !call getExpr()) {
                    // add `this` if needed.
                    call setExpr(VariableAccess new("this", call token))
                }
            }
        )

        return 0
    }

    resolveAccess: func (access: VariableAccess, res: Resolver, trail: Trail) -> Int {
        if(base == null) return 0

        vDecl := properties[access name]
        if(vDecl) {
            if(access suggest(vDecl)) {
                // If we are trying to access the property's variable declaration from its own getter or setter,
                //  we would need to define a new field for this type, which is impossible
                if(!vDecl inOuterSpace(trail)) {
                    res throwError(ExtendFieldDefinition new(vDecl token, "Property tries to define a field in type extension." ))
                }
            }
        }

        // If we aren't looking for a property, we may be looking for a typeArg
        // In this case, we need our type's base to forward it's typeArg declaration
        if (!base isResolved()) {
            res wholeAgain(this, "need baseType ref")
            return 0
        }

        // Let's try to find the index of the typeArg we tried to index
        for ((i, typeArg?) in typeArgs) {
            if (typeArg? inner as BaseType name == access name) {
                // Bingo! Found a match.
                // All we need to do is suggest the VariableDecl of the typeArg present in our base at the same index.
                access suggest(base typeArgs[i])
                return 0
            }
        }

        0
    }

    toString: func -> String {
        "Addon of %s in module %s" format(baseType toString(), token module getFullName())
    }

}

ExtendFieldDefinition: class extends Error {
    init: super func ~tokenMessage
}

InvalidTypeargType: class extends Error {
    init: super func ~tokenMessage
}

InvalidGenericExtention: class extends Error {
    init: super func ~tokenMessage
}
