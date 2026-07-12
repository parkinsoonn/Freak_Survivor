using UnityEditor;
using UnityEditor.SceneManagement;


[InitializeOnLoad]
public class PlayFromMenu
{
    
    static PlayFromMenu()
    {
        
        if (EditorBuildSettings.scenes.Length > 0)
        {
            string scenePath = EditorBuildSettings.scenes[0].path;
            SceneAsset startScene = AssetDatabase.LoadAssetAtPath<SceneAsset>(scenePath);

            
            EditorSceneManager.playModeStartScene = startScene;
        }
    }
}