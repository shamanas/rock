import io/[FileReader]
import text/[StringTokenizer]
import structs/[ArrayList, HashMap]

import Driver
import rock/frontend/[BuildParams]
import rock/middle/[Module, TypeDecl, FunctionDecl, VariableDecl]

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
        for (currentModule in module collectDeps()) {
            processModule(currentModule)
        }
        processModule(module)
        "Obfuscation done, compiling..." printfln()
        params driver compile(module)
    }
    processModule: func (module: Module) {
        if (targets contains?(module simpleName)) {
            target := targets get(module simpleName)
            "  Module: #{target oldName} -> #{target newName}" printfln()
            module simpleName = target newName
            module underName = module underName substring(0, module underName indexOf(target oldName)) append(target newName)
        }
        // For now, this must live outside the above if-statement, since obfuscation targets may
        // be present in non-target modules. 
        for (type in module types) {
            if (targets contains?(type name)) {
                target := targets get(type name)
                "  Type:   #{target oldName} -> #{target newName}" printfln()
                type name = target newName
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
                result put(temp[0] + "Class", ObfuscationTarget new(temp[0] + "Class", temp[1] + "Class", ObfuscationTargetType Type))
            }
        }
        result
    }
}
