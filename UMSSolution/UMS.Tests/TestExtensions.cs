using System.Reflection;

namespace UMS.Tests
{
    public static class TestExtensions
    {
        public static TEntity SetId<TEntity, TId>(this TEntity entity, TId id)
        {
            var type = typeof(TEntity);
            PropertyInfo? propertyInfo = null;

            while (propertyInfo == null && type != null)
            {
                propertyInfo = type.GetProperty("Id", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                type = type.BaseType;
            }

            if (propertyInfo != null && propertyInfo.CanWrite)
            {
                propertyInfo.SetValue(entity, id);
            }
            else if (propertyInfo != null)
            {
                // If it doesn't have a setter, try the backing field
                var fieldInfo = propertyInfo.DeclaringType?.GetField("<Id>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic);
                fieldInfo?.SetValue(entity, id);
            }
            
            return entity;
        }
    }
}
