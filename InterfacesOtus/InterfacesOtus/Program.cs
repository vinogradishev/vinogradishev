namespace InterfacesOtus
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Quadcopter quad1 = new Quadcopter();
            
            Console.WriteLine(quad1.GetRobotType());
            Console.WriteLine(((IChargeable)quad1).GetInfo());
            quad1.Charge();
            Console.WriteLine(((IChargeable)quad1).GetInfo());
            Console.WriteLine(quad1.GetInfo());
            Console.WriteLine("----------------------------");
            
            CubeRobot cube1 = new CubeRobot();
            
            Console.WriteLine(cube1.GetRobotType());
            Console.WriteLine(((IChargeable)cube1).GetInfo());
            cube1.Charge();
            Console.WriteLine(((IChargeable)cube1).GetInfo());
            Console.WriteLine(cube1.GetInfo());
            
        }
    }
}