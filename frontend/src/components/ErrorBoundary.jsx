import { Component } from "react";
class ErrorBoundary extends Component {
    constructor(props){
        super(props)
        this.state = {
            hasError: false,
            error: null,
            errorInfo: null
        }
    }

    static getDerivedStateFromError(error){
        return { hasError: true }
    }

    componentDidCatch(error, errorInfo){
        console.error('ErrorBoundary 捕捉到錯誤:', error, errorInfo)

        this.setState({
            error: error,
            errorInfo: errorInfo
        })
    }
    handleReset = () => {
        this.setState({
            hasError: false,
            error: null,
            errorInfo: null
        })
    }

    render() {
        if(this.state.hasError){
            return(
                <div className="min-h-screen bg-gray-100 flex items-center justify-center px-4">
                    <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
                        <div className="flex justify-center mb-4">
                            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                                <svg
                                  className="w-8 h-8 text-red-600"
                                  fill="none"
                                  stroke="currentColor"
                                  viewBox="0 0 24 24">
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                                </svg>
                            </div>
                        </div>

                        <h1 className="text-2xl font-bold text-gray-800 text-center mb-2">
                            糟糕！發生錯誤
                        </h1>
                        <p className="text-gray-600 text-center mb-6">
                            系統遇到了一個問題。我們已經記錄此錯誤，請稍後再試。
                        </p>
                        {/* 開發環境顯示錯誤詳情 */}
                        {process.env.NODE_ENV === 'development' && this.state.error && (
                            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded">
                                <p className="text-sm font-mono text-red-800 mb-2">
                                    {this.state.error.toString()}
                                </p>
                                {this.state.errorInfo && (
                                    <details className="text-xs text-red-700">
                                        <summary className="cursor-pointer font-semibold mb-1">
                                            詳細資訊
                                        </summary>
                                        <pre className="whitespace-pre-wrap overflow-auto max-h-40">
                                            {this.state.errorInfo.componentStack}
                                        </pre>
                                    </details>
                                )}
                            </div>
                        )}

                        <div className="flex flex-col gap-3">
                            <button
                              onClick={() => window.location.href = '/dashboard'}
                              className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
                                返回首頁
                            </button>
                            <button
                              onClick={this.handleReset}
                              className="w-full bg-gray-200 text-gray-700 py-3 rounded-lg font-semibold hover:bg-gray-300 transition">
                                重試
                            </button>
                        </div>
                    </div>
                </div>
            )
        }


        return this.props.children
    }
}

export default ErrorBoundary