using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ReRe
{
    public class MaterialLabel : MonoBehaviour
    {
        [SerializeField] Transform target;
        [SerializeField] Camera targetCamera;
        [SerializeField] Vector3 offset = new Vector3(0, 0, 1);

        RectTransform parent;

        private void Start()
        {
            var canvasSizeEventHandler = GetComponentInParent<CanvasSizeEventHandler>();
            canvasSizeEventHandler?.CanvasChangeEvent.AddListener(UpdatePosition);
            UpdatePosition();
        }

        void UpdatePosition()
        {
            if (target == null) return;
            if (targetCamera == null) return;
            var targetWorldPos = target.position + offset;
            var targetScreenPos = targetCamera.WorldToScreenPoint(targetWorldPos);

            parent ??= transform.parent.GetComponent<RectTransform>();
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(
                parent,
                targetScreenPos,
                null, out var localPos))
            {
                transform.localPosition = localPos;
            }
        }

        private void OnValidate()
        {
            UpdatePosition();
        }
    }
}