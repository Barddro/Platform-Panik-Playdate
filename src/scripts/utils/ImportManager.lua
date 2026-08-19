-- TODO: automatically handles import ordering by forming a dependency tree and resolving/simplifying it to make imports independent from import order/hierarchy (ie. we can import at the file-level)

-- first, we build dependency graph (directed), and then detect and resolve all cycles until DAG

-- may also want to capture all code execution of first 'import' into a table 'module_name', then when a file calls module_name_var = ImportManager:import("module_name"), weak return table "module_name", and then the file can invoke methods and such