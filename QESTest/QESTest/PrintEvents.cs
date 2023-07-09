using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Otus_Methods
{
    internal class PrintEvents
    {
        public static void PrintMenuCoefficient()
        {
            string printA = $"1.a:{SolvingTheQuadraticEquation._valueOfCoefficient[0],-10}";
            string printB = $"2.b:{SolvingTheQuadraticEquation._valueOfCoefficient[1],-10}";
            string printC = $"3.c:{SolvingTheQuadraticEquation._valueOfCoefficient[2],-10}";
            if (SolvingTheQuadraticEquation._selectedValue == 1)
            {
                Console.WriteLine(">" + printA + "          ");
                Console.WriteLine(printB + "          ");
                Console.WriteLine(printC + "          ");
            }
            else if (SolvingTheQuadraticEquation._selectedValue == 2)
            {
                Console.WriteLine(printA + "          ");
                Console.WriteLine(">" + printB + "          ");
                Console.WriteLine(printC + "          ");
            }
            else if (SolvingTheQuadraticEquation._selectedValue == 3)
            {
                Console.WriteLine(printA + "          ");
                Console.WriteLine(printB + "          ");
                Console.WriteLine(">" + printC + "          ");
            }
            else
            {
                Console.WriteLine(printA + "          ");
                Console.WriteLine(printB + "          ");
                Console.WriteLine(printC + "          ");
            }
        }
        public static void PrintEquation()
        {
            string printA = string.IsNullOrEmpty(SolvingTheQuadraticEquation._valueOfCoefficient[0]) ? "a" : SolvingTheQuadraticEquation._valueOfCoefficient[0];
            string printB = string.IsNullOrEmpty(SolvingTheQuadraticEquation._valueOfCoefficient[1]) ? "b" : SolvingTheQuadraticEquation._valueOfCoefficient[1];
            string printC = string.IsNullOrEmpty(SolvingTheQuadraticEquation._valueOfCoefficient[2]) ? "c" : SolvingTheQuadraticEquation._valueOfCoefficient[2];

            //string printEquation = string.Format("{0, -46}", equation);
            Console.Write($"{printA} * x^2 + {printB} * x + {printC} = 0"); Console.WriteLine(", Enter - подтверждение ввода, Backspace - стереть всё.                              ");
        }
    }
}
