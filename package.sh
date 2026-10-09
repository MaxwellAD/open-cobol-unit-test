# This script is used to package releases of Open COBOL Unit Test
# ./package.sh <release version>
# Creates open-cobol-unit-test-<release version>.tar

version=${1}

# What gets included
files_to_package="CUT/* harness.sh cobtest cobtestrun"

# The name of the package including version number
package_name="open-cobol-unit-test-${version}.tar"
tar -cf ${package_name} ${files_to_package}
printf "Packaged ${package_name} \n"
printf "    Containing -> ${files_to_package}\n"
