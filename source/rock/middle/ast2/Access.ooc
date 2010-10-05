

import tinker/Resolver
import Expression, Type, Var

Access: class extends Expression {

    name: String { get set }
    expr: Expression { get set }
    
    ref: Var { get set }

    init: func (=expr, =name) {}

    getType: func -> Type {
        ref ? ref type : null
    }

    toString: func -> String {
        name
    }

    resolve: func (task: Task) {
        task walkBackward(|node|
            node resolveAccess(this, task, |var|
                // TODO: break on resolve - also, do we need a sugg-like class?
                ref = var
            )
        )
        if(!ref)
            Exception new("Couldn't resolve access to " + name) throw()
        
        task done()
    }

}