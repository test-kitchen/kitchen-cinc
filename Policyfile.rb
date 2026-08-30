name "kitchen-cinc"

run_list "test_cookbook"

cookbook "test_cookbook", path: "test/cookbooks/test_cookbook"
