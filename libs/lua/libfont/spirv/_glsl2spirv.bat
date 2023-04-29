@echo off
rem glslangValidator -h > help.txt

glslangValidator font-vs.vert -V -o font-vs.spv
glslangValidator font-ps.frag -V -o font-ps.spv

pause