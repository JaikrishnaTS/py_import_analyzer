#!/bin/bash

# https://www.python.org/dev/peps/pep-0328/#guido-s-decision
# from . import module -> cwd/module.py

# from .module import member -> cwd/module.py
# from .subpackage import module -> cwd/subpackage/module.py

# from .subpackage.submodule import member -> cwd/subpackage/submodule/module.py
# from .subpackage.subsubpackage import module -> cwd/subpackage/submodule/module.py

# from ..subpackage import module -> cwd/../subpackage/module.py
# from pkg.filename import member

# from .x.y.z import a, b
#   if cwd/x/y/z is dir
#       try cwd/x/y/z/a.py 
#       try cwd/x/y/z/b.py 
#   else
#       try cwd/x/y/z.py

# from x.y import a, b
#   if /x/y is dir
#       try /x/y/a.py 
#       try /x/y/b.py 
#   else
#       try /x/y.py

get_py_path () {
    local given=${1:-input relative path is required}
    local cwd=${2:-current working dir is required}
    local gnpath=(${given//./\/ })
    for i in ${!gnpath[@]}; do
        if [[ ${i} == 0 && ${gnpath[0]} == '/' ]]; then
            echo -n ${cwd}/
        elif [[ ${gnpath[${i}]} == '/' ]]; then
            echo -n '../'
        else
            echo -n ${gnpath[${i}]}
        fi
    done
}


print_py_imports () {
    local filepath=${1:-python file to analyze is required}
    local from_re='^from\ (.*)\ import\ (.*)$'
    local part_path
    local item_path
    local dirpath
    local mods
    local pymatched

    while read -r line; do
        if [[ ${line} =~ ${from_re} ]]; then
            part_path=${BASH_REMATCH[1]}
            item_path=${BASH_REMATCH[2]}
            #echo ${part_path} ${item_path}
            dirpath=$(get_py_path ${part_path} $(dirname $1))
            #echo "${dirpath}"
            if [[ -d ${dirpath} ]]; then
                mods=(${item_path//,/})
                pymatched=false
                for item in ${mods[@]}; do
                    if [[ -f "${dirpath}/${item}.py" ]]; then
                        pymatched=true
                        echo "${filepath} ${dirpath}/${item}.py"
                    fi
                done
                if [[ ${pymatched} == false && -f "${dirpath}/__init__.py" ]]; then
                    echo "${filepath} ${dirpath}/__init__.py"
                fi
            elif [[ -f "${dirpath}.py" ]]; then
                echo "${filepath} ${dirpath}.py"
            fi
            #echo -e "\n\n"
        fi
    done < ${filepath}
}

for pyfile in $(find $1 -type f -name '*.py'); do
    print_py_imports ${pyfile}
done
