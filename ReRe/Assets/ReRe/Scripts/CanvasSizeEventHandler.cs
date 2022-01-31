using UnityEngine;
using UnityEngine.Events;

namespace ReRe
{

    public class CanvasSizeEventHandler : MonoBehaviour
    {
        public UnityEvent CanvasChangeEvent { get; } = new UnityEvent();
        private void OnRectTransformDimensionsChange()
        {
            CanvasChangeEvent.Invoke();
        }
    }
}