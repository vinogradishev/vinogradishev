using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Otus_Methods
{
    internal class MoveCursorFunc
    {
        public static void NoCursor(int pos)
        {
            Console.SetCursorPosition(0, pos);
            Console.WriteLine(" ");
            Console.SetCursorPosition(0, pos);
        }
        public static void SetDown()
        {
            if (SolvingTheQuadraticEquation._selectedValue < SolvingTheQuadraticEquation._coefficients.Length)
            {
                SolvingTheQuadraticEquation._selectedValue++;
            }
            else
            {
                SolvingTheQuadraticEquation._selectedValue = 1;
            }
        }
        public static void SetUp()
        {
            if (SolvingTheQuadraticEquation._selectedValue > 1)
            {
                SolvingTheQuadraticEquation._selectedValue--;
            }
            else
            {
                SolvingTheQuadraticEquation._selectedValue = 3;
            }
        }
    }
}
