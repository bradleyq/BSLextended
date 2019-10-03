#define WorldCurvatureSize 256 //[16 32 64 128 256 512 1024 2048 4096]

float worldCurvature(vec2 pos){
    return dot(pos,pos)/WorldCurvatureSize;
}