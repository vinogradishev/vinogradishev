using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace InterfacesOtus
{
    internal class CubeRobot : IRobot, IChargeable
    {
        List<string> _list_components;

        bool _charged = false;

        string Charged
        {
            get
            {
                if (_charged)
                {
                    return "I am charged";
                }
                else
                {
                    return "I am not charged";
                }
            }
        }
        public string GetInfo()
        {
            return "I am a Flying robot with 2 hands and 2 wheels.";
        }
        string IChargeable.GetInfo()
        {
            return Charged;
        }
        public List<string> GetComponents()
        {
            return _list_components;
        }
        public void Charge()
        {
            Console.WriteLine("Charging...");
            Thread.Sleep(3000);
            Console.WriteLine("Cherged");
            _charged = true;
        }
        public string GetRobotType()
        {
            return "I am a simple robot.";
        }
        public CubeRobot() 
        {
            _list_components = new List<string> { "wheel1", "wheel2", "hand1", "hand2" };
        }
    }
}
