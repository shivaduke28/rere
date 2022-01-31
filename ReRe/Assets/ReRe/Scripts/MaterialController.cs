using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ReRe
{
    public class MaterialController : MonoBehaviour
    {
        [SerializeField] Renderer[] renderers;
        [SerializeField] PropertySlider[] propertySliders;

        private void Start()
        {
            Initialize();
        }

        void Initialize()
        {
            foreach (var propertySlider in propertySliders)
            {
                var propertyId = Shader.PropertyToID(propertySlider.propertyName);
                propertySlider.slider.onValueChanged.AddListener(x => UpdateFloatProperty(propertyId, x));
            }
        }

        void UpdateFloatProperty(int propertyId, float value)
        {
            foreach (var renderer in renderers)
            {
                var material = renderer.material;
                if (material.HasProperty(propertyId))
                {
                    material.SetFloat(propertyId, value);
                }
            }
        }


        [Serializable]
        public class PropertySlider
        {
            public string propertyName;
            public Slider slider;
        }
    }
}