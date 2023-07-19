namespace StackOtus
{
    class TestStackMethods
    {
        static void Main()
        {
            var s = new Stack("a", "b", "c");
            // size = 3, Top = 'c'
            Console.WriteLine($"size = {s.Size}, Top = '{s.Top}'");
            var deleted = s.Pop();
            // Извлек верхний элемент 'c' Size = 2
            Console.WriteLine($"Извлек верхний элемент '{deleted}' Size = {s.Size}");
            s.Add("d");
            // size = 3, Top = 'd'
            Console.WriteLine($"size = {s.Size}, Top = '{s.Top}'");
            s.Pop();
            s.Pop();
            s.Pop();
            // size = 0, Top = null
            Console.WriteLine($"size = {s.Size}, Top = {(s.Top == null ? "null" : s.Top)}");
            s.Pop();
            var a = new Stack("a", "b", "c", "d", "e");
            a.Merge(new Stack("1", "2", "3", "4", "5"));

            foreach (var x in a.stackProp)
            {
                Console.Write(x + " ");
            }
            Console.WriteLine();
            Console.WriteLine("-------------------------------");

            s = Stack.Concat(new Stack("a", "b", "c"), new Stack("1", "2", "3"), new Stack("А", "Б", "В"));
            foreach (var x in s.stackProp)
            {
                Console.Write(x + " ");
            }
        }
    }
}