#!/bin/bash 

include={{INCLUDE}}
config_path={{CONFIG_PATH}}

if [[ "$include" ]]; then
    echo "include: $include"
    echo 
fi

if [[ "$config_path" ]]; then 
    cat "$config_path"
fi

echo