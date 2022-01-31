using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ReRe
{


    public class LightController : MonoBehaviour
    {
        [SerializeField] Slider pitchSlider;
        [SerializeField] Slider yawSlider;
        [SerializeField] Light light;

        void Start()
        {
            Initialize();
        }
        void Initialize()
        {
            pitchSlider.onValueChanged.AddListener(value =>
            {
                var euler = light.transform.rotation.eulerAngles;
                euler.x = value;
                light.transform.rotation = Quaternion.Euler(euler);
            });
            yawSlider.onValueChanged.AddListener(value =>
            {
                var euler = light.transform.rotation.eulerAngles;
                euler.y = value;
                light.transform.rotation = Quaternion.Euler(euler);
            });
        }
    }
}
