import io/[FileReader]
import text/[StringTokenizer]
import structs/[ArrayList, HashMap]

import Driver
import rock/frontend/[BuildParams]
import rock/middle/[Module, TypeDecl, FunctionDecl, VariableDecl, StructLiteral, FunctionCall]

ObfuscationTargetType: enum {
    Unknown,
    Type,
    Function
}
ObfuscationTarget: class {
    oldName: String
    newName: String
    type := ObfuscationTargetType Unknown
    init: func (=oldName, =newName, =type)
}
//
// At this point, this is more like a hack than anything else. We should probably
// defer the obfuscation to a AST walk just before the C-generation pass.
//
Obfuscator: class extends Driver {
    targets: HashMap<String, ObfuscationTarget>
    init: func(.params, mappingFile: String) {
        super(params)
        targets = parseMappingFile(mappingFile)
    }
    compile: func (module: Module) -> Int {
        "Obfuscating..." printfln()
        for (currentModule in module collectDeps())
            processModule(currentModule)
        processModule(module)
        "Obfuscation done, compiling..." printfln()
        params driver compile(module)
    }
    processModule: func (module: Module) {
        if (targets contains?(module simpleName)) {
            target := targets get(module simpleName)
            module simpleName = target newName
            module underName = module underName substring(0, module underName indexOf(target oldName)) append(target newName)
            module isObfuscated = true
            for (statement in module body) {
                if (statement instanceOf?(VariableDecl) && !statement as VariableDecl getType() instanceOf?(AnonymousStructType)) {
                    vd := statement as VariableDecl
                    if (vd isExtern() && !vd isProto())
                        continue
                    if (vd name contains?(target oldName))
                        vd name = vd name replaceAll(target oldName, target newName)
                }
            }
        }
        // For now, this must live outside the above if-statement, since obfuscation targets may
        // be present in non-target modules.
        for (type in module types) {
            if (targets contains?(type name)) {
                target := targets get(type name)
                type name = target newName
                for (function in type functions) {
                    // trim(String) is buggy, so use substring and indexOf instead.
                    // TODO: What happens if a type actually has the word "Class" in its name?
                    functionCandidate := target oldName substring(0, target oldName indexOf("Class")) + "." + function name
                    if (targets contains?(functionCandidate))
                        function name = targets get(functionCandidate) newName
                }
            }
        }
    }
    parseMappingFile: func (mappingFile: String) -> HashMap<String, ObfuscationTarget> {
        result := HashMap<String, ObfuscationTarget> new(15)
        reader := FileReader new(mappingFile)
        content := ""
        while (reader hasNext?())
            content = content append(reader read())
        reader close()
        targets := content split('\n')
        for (target in targets) {
            temp := target split(':')
            if (temp size > 1) {
                result put(temp[0], ObfuscationTarget new(temp[0], temp[1], ObfuscationTargetType Type))
                if (!temp[0] contains?('.'))
                    result put(temp[0] + "Class", ObfuscationTarget new(temp[0] + "Class", temp[1] + "Class", ObfuscationTargetType Type))
            }
        }
        result
    }
}
