import gradio as gr

def echo(text, n):
    return text * n

def increment(count):
    return count + 1

with gr.Blocks(title="Toy Gradio App", theme=gr.themes.Soft()) as demo:
    gr.Markdown(
        """
        # Toy Gradio App
        This Gradio preview is running inside the **opencode-web** pod.
        """
    )
    with gr.Row():
        with gr.Column():
            inp = gr.Textbox(label="Say something")
            btn_echo = gr.Button("Echo")
            out = gr.Textbox(label="Echo", interactive=False)
        with gr.Column():
            count = gr.Number(label="Times to repeat", value=1, interactive=True)
            btn_inc = gr.Button("Increment")
    btn_echo.click(echo, inputs=[inp, count], outputs=out)
    btn_inc.click(increment, inputs=count, outputs=count)
    gr.Markdown(f"Random preview token: {__import__('random').randint(1000, 9999)}")

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=8411)