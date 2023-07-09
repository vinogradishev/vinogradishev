using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Otus_Methods
{
    internal class Menu
    {
        public static void StartMenu()
        {
            ConsoleKeyInfo ki;

            SolvingTheQuadraticEquation._selectedValue = 1;

            PrintEvents.PrintEquation();
            PrintEvents.PrintMenuCoefficient();
            do
            {
                Console.SetCursorPosition(0, 0);
                PrintEvents.PrintEquation();
                Console.SetCursorPosition(0, SolvingTheQuadraticEquation._selectedValue);
                ki = Console.ReadKey();
                AddValueToVariable(ki.KeyChar);
                MoveCursorFunc.NoCursor(SolvingTheQuadraticEquation._selectedValue);
                switch (ki.Key)
                {
                    case ConsoleKey.UpArrow:
                        MoveCursorFunc.SetUp();
                        break;
                    case ConsoleKey.DownArrow:
                        MoveCursorFunc.SetDown();
                        break;
                    case ConsoleKey.Backspace:
                        SolvingTheQuadraticEquation._valueOfCoefficient[0] = "";
                        SolvingTheQuadraticEquation._valueOfCoefficient[1] = "";
                        SolvingTheQuadraticEquation._valueOfCoefficient[2] = "";
                        break;
                }
                if (ki.Key == ConsoleKey.Enter)
                {
                    SolvingTheQuadraticEquation._selectedValue = 4;
                    Console.SetCursorPosition(0, 1);
                    PrintEvents.PrintMenuCoefficient();
                    Console.SetCursorPosition(0, 5);
                    Discriminant.CalculateDiscriminant(
                        SolvingTheQuadraticEquation._valueOfCoefficient[0], 
                        SolvingTheQuadraticEquation._valueOfCoefficient[1], 
                        SolvingTheQuadraticEquation._valueOfCoefficient[2]);
                    break;
                }
                Console.SetCursorPosition(0, 0);
                PrintEvents.PrintEquation();
                Console.SetCursorPosition(0, 1);
                PrintEvents.PrintMenuCoefficient();
                //PrintCursor(selectedValue);
            } while (ki.Key != ConsoleKey.Escape);
        }
        public static void AddValueToVariable(char valueToAdd)
        {
            if ((SolvingTheQuadraticEquation._selectedValue == 1 && char.IsAsciiLetterOrDigit(valueToAdd)) ||
                (SolvingTheQuadraticEquation._selectedValue == 1 && valueToAdd == '-'))
            {
                SolvingTheQuadraticEquation._valueOfCoefficient[0] += Convert.ToString(valueToAdd);
            }
            else if ((SolvingTheQuadraticEquation._selectedValue == 2 && char.IsAsciiLetterOrDigit(valueToAdd)) ||
                     (SolvingTheQuadraticEquation._selectedValue == 2 && valueToAdd == '-'))
            {
                SolvingTheQuadraticEquation._valueOfCoefficient[1] += Convert.ToString(valueToAdd);
            }
            else if ((SolvingTheQuadraticEquation._selectedValue == 3 && char.IsAsciiLetterOrDigit(valueToAdd)) ||
                     (SolvingTheQuadraticEquation._selectedValue == 3 && valueToAdd == '-'))
            {
                SolvingTheQuadraticEquation._valueOfCoefficient[2] += Convert.ToString(valueToAdd);
            }
        }
    }
}
