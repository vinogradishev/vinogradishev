﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InterfacesOtus
{
    internal interface IRobot
    {
        string GetInfo();
        List<string> GetComponents();
        string GetRobotType() 
        {
            return "I am a simple robot.";
        }
    }
}
