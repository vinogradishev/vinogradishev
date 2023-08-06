using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InterfacesOtus
{
    internal class Quadcopter : IFlyingRobot, IChargeable
    {
        List<string> _list_components;

        bool _charged = false;

        string Charged 
        {
            get 
            {
                if (_charged) 
                {
                    return $"I am a Flying robot with {_list_components.Count} rotors, and I am charged";
                }
                else 
                {
                    return $"I am a Flying robot with {_list_components.Count} rotors, and I am not charged";
                }
            }
        }
        public string GetInfo() 
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
            return "I am a flying robot.";
        }
        public Quadcopter() 
        {
            _list_components = new List<string> { "rotor1", "rotor2", "rotor3", "rotor4" };
        }
    }
}
