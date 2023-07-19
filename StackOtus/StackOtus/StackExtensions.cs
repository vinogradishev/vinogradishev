namespace StackOtus
{
    internal static class StackExtensions
    {
        static List<string>? _mergeStackList1;

        public static void Merge(this Stack stack1, Stack stack2)
        {
            int stackSize = stack2.Size;
            for (int i = 0; i < stackSize; i++)
            {
                string insertStr = stack2.Pop();
                stack1.Add(insertStr);
            }
        }
    }
}
