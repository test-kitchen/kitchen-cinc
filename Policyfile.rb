name "kitchen-cinc"

default_source :supermarket

run_list "test_cookbook"

cookbook "test_cookbook", path: "test/cookbooks/test_cookbook"
