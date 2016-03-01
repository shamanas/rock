import io/[FileReader]
import text/[StringTokenizer]
import structs/[ArrayList, HashMap]

import Driver
import rock/frontend/[BuildParams]
import rock/middle/[Module, TypeDecl, FunctionDecl]

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
Obfuscator: class extends Driver {
    targets: HashMap<String, ObfuscationTarget>
    init: func(.params, mappingFile: String) {
        super(params)
        targets = parseMappingFile(mappingFile)
    }
    compile: func (module: Module) -> Int {
        for (currentModule in module collectDeps()) {
            if (targets contains?(currentModule simpleName)) {
                target := targets get(currentModule simpleName)
                currentModule simpleName = target newName
                currentModule underName = currentModule underName substring(0, currentModule underName indexOf(target oldName)) append(target newName)
            }
            for (type in currentModule types) {
                if (targets contains?(type name)) {
                    type name = targets get(type name) newName
                    if (type isMeta) {
                        "meta: #{type meta toString()}" printfln()
                    }
                    "name: #{type getName()}" printfln()
                }
            }
        }
        params driver compile(module)
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
            if (temp size > 1)
                result put(temp[0], ObfuscationTarget new(temp[0], temp[1], ObfuscationTargetType Type))
        }
        result
    }
}
