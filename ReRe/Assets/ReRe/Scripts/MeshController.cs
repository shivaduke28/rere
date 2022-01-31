using System;
using UnityEngine;
using UnityEngine.UI;

namespace ReRe
{
    public class MeshController : MonoBehaviour
    {
        [SerializeField] MeshButton[] meshButtons;
        [SerializeField] MeshFilter[] meshFilters;
        void Start()
        {
            Initialize();
        }

        void Initialize()
        {
            foreach(var meshButton in meshButtons)
            {
                meshButton.button.onClick.AddListener(() =>
                {
                    foreach (var meshFilter in meshFilters)
                    {
                        meshFilter.mesh = meshButton.mesh;
                        meshFilter.transform.localScale = Vector3.one * meshButton.scale;
                    }
                });
            }
        }


        [Serializable]
        public class MeshButton
        {
            public Mesh mesh;
            [Range(0.01f, 10f)] public float scale;
            public Button button;
        }
    }
}