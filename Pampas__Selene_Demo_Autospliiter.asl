// Pampas & Selene Demo Autosplitter
// Created by NickRPGreen 

state("maze"){
    float GlobalTimer: "maze.exe", 0xCABC70;    // In-Game Global Timer
    float GameTimer: "maze.exe", 0xCABC74;      // In-Game Game Timer
    int Area: "maze.exe", 0x3A3EB48;            // Current Area of the Game - 0=Castle, 1=Cyclops
    int Room: "maze.exe", 0x3A3E954;            // Current Room
    int State: "maze.exe", 0xCAB8B0;            // Game State: 0=Main Menu, 1=In Game 
}

init{
    refreshRate = 60;
    vars.Boss = 0; //Tracks if you've already visited the boss room
}

split{
    if(old.Area == 0 && current.Area == 1) return true;
    if(old.Room == 35778376 && current.Room == 35737456 && vars.Boss == 0) {
        vars.Boss = 1;
        return true;
    }
    if(old.GlobalTimer == current.GlobalTimer) return true;
}

start{
    return old.GameTimer == 0 && current.GameTimer > 0 && current.State == 1;
}

gameTime
{
    return TimeSpan.FromSeconds(current.GameTimer);
}

isLoading
{
    return true;
}

reset{
    if(old.State == 1 && current.State == 0) return true;
}

onStart
{
    vars.Boss = 0;
}
